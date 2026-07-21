import asyncio
from aiohttp import web
import json
import urllib

from urdf_parser_py import urdf as urdf_parser
from scipy.spatial.transform import Rotation as R

from .server import ServerBase
from . import utils

# ros handle
from . import ros_utils
ros_handle : ros_utils.RosWrapper = ros_utils.ros_handle

if ros_handle.ros_version == 1:
    from sensor_msgs import point_cloud2 as pc2
from sensor_msgs.msg import PointCloud2, Range

from threading import Lock
from functools import partial

# class RoundingFloat(float):
#     __repr__ = staticmethod(lambda x: format(x, '.3f'))

# json.encoder.c_make_encoder = None
# json.encoder.float = RoundingFloat

class VisualHandler:

    def __init__(self, srv: ServerBase, config=dict()) -> None:

        # config
        self.rate = config.get('rate', 10.0)
        
        # Colori configurabili per environment
        self.environment_colors = config.get('environment_colors', {
            'world': [0.5, 0.5, 0.5],    # grigio scuro (muri)
            'table': [0.8, 0.6, 0.4],   # marrone (tavolo)
            'fluent': [0.2, 0.4, 0.8],  # blu scuro (tecan fluent)
            'spark': [0.2, 0.4, 0.8],   # blu scuro (tecan spark)
            'rack': [0.6, 0.8, 0.6],    # verde (rack)
            'cap': [0.2, 0.2, 0.2],     # blu elettrico (cap box/station)
        })
        self.default_color = config.get('default_environment_color', [0.7, 0.7, 0.7])

        # save server object, register our handlers
        self.srv = srv

        self.srv.add_route('GET', '/visual/get_mesh/{uri}',
                           self.visual_get_mesh_handler,
                           'visual_get_mesh_handler')

        self.srv.add_route('GET', '/visual/get_mesh_entities',
                           self.visual_get_mesh_entities,
                           'visual_get_mesh_entities')
        
        self.srv.add_route('GET', '/visual/get_environment_entities',
                           self.visual_get_environment_entities,
                           'visual_get_environment_entities')

        # self.srv.add_route('GET', '/visual/get_mesh_tfs',
        #                    self.visual_get_mesh_tfs,
        #                    'visual_get_mesh_tfs')         

        self.srv.add_route('GET', '/visual/get_pointcloud',
                           self.visual_get_pc,
                           'visual_get_pc')     

        self.srv.add_route('GET', '/visual/get_sonar',
                           self.visual_get_sonar,
                           'visual_get_sonar')   
        
        self.srv.schedule_task(self.run())

        self.srv.register_ws_coroutine(self.handle_ws)

        # point clouds
        self.pc_lock = Lock()
        pc_topics = ['/VLP16_lidar_back/velodyne_points', '/VLP16_lidar_front/velodyne_points']
        self.pc_subs = [ros_handle.create_subscription(PointCloud2, t, lambda msg: self.on_pc_recv(msg, t), queue_size=1) for t in pc_topics]      
        self.pc_map = {t: [] for t in pc_topics}
        self.pc_frame_map = {t: None for t in pc_topics}
        self.pc_client_ids = set()
        
        # sonar topics
        sonar_topics = [
            '/bosch_uss5/ultrasound_fl_lat',      
            '/bosch_uss5/ultrasound_fl_sag',      
            '/bosch_uss5/ultrasound_fr_lat',      
            '/bosch_uss5/ultrasound_fr_sag',      
            '/bosch_uss5/ultrasound_rl_lat',      
            '/bosch_uss5/ultrasound_rl_sag',      
            '/bosch_uss5/ultrasound_rr_lat',      
            '/bosch_uss5/ultrasound_rr_sag',  
            ]
        
        self.sonar_subs = [ros_handle.create_subscription(Range, t, lambda msg: self.on_sonar_recv(msg, t), queue_size=1) for t in sonar_topics]
        self.sonar_map = {t: None for t in sonar_topics}
        self.sonar_frame_map = {t: None for t in sonar_topics}

        
    async def handle_ws(self, msg, proto, ws):
        if msg['type'] == 'pc_registration':
            cli_id = int(msg['cli_id'])
            if cli_id not in self.pc_client_ids:
                self.pc_client_ids.append(cli_id)
                print(f'registered client id {cli_id}: total is {len(self.pc_client_ids)}')
        elif msg['type'] == 'pc_unregistration':
            cli_id = int(msg['cli_id'])
            del self.pc_client_ids[self.pc_client_ids.index(cli_id)]
    

    @utils.handle_exceptions
    async def visual_get_pc(self, req: web.Request):

        if ros_handle.ros_version != 1:
            raise RuntimeError('requires ROS1')
         
        tfl = tf.TransformListener()

        res = {}
        
        for pcname, pcframe in self.pc_frame_map.items():
            await utils.to_thread(tfl.waitForTransform, source_frame=pcframe, target_frame='base_link', time=rospy.Time(0), timeout=rospy.Duration(2.0))
            pos, rot = tfl.lookupTransform(source_frame=pcframe, target_frame='base_link', time=rospy.Time(0))
            print(f'{pcname} {pcframe} {pos} {rot}')
            res[pcname] = dict(pos=pos, rot=rot)

        del tfl

        return web.json_response(res)

    
    @utils.handle_exceptions
    async def visual_get_sonar(self, req: web.Request):

        if ros_handle.ros_version != 1:
            raise RuntimeError('requires ROS1')
        
        tfl = tf.TransformListener()

        res = {}
        
        for sname, sframe in self.sonar_frame_map.items():
            await utils.to_thread(tfl.waitForTransform, source_frame=sframe, target_frame='base_link', time=rospy.Time(0), timeout=rospy.Duration(2.0))
            pos, rot = tfl.lookupTransform(source_frame=sframe, target_frame='base_link', time=rospy.Time(0))
            print(f'{sname} {sframe} {pos} {rot}')
            res[sname] = dict(pos=pos, rot=rot)

        del tfl

        return web.json_response(res)


    async def run_loop(self):

        await self.srv.udp_send_to_all({
                'type': 'sonar',
                'range': self.sonar_map
            })
                    
        self.pc_client_ids = [cli_id for cli_id in self.pc_client_ids if cli_id in self.srv.client_id_ws_map]
        
        with self.pc_lock:
            for k, v in self.pc_map.items():
                for i, m in enumerate(v):
                    await self.srv.udp_send_to_all(m) # client_ids=self.pc_client_ids) 
                

    async def run(self):

        async def print_err(msg):
            print(msg)

        wrapped = utils.sync_loop(self.run_loop, dt=0.1, on_exception=print_err)
        await wrapped()

    
    def on_sonar_recv(self, msg: Range, sname):

        self.sonar_frame_map[sname] = msg.header.frame_id
        self.sonar_map[sname] = msg.range


    def on_pc_recv(self, msg: PointCloud2, pcname):

        self.pc_frame_map[pcname] = msg.header.frame_id

        if len(self.pc_client_ids) == 0:
            return

        points = list(pc2.read_points(msg, field_names=('x', 'y', 'z')))

        blksize = 500 // (4 * 3)

        nblk = len(points) // blksize + 1

        msgs = []
        
        for i in range(nblk): 
            istart = i * blksize
            iend = min(istart + blksize, len(points))

            msg = json.dumps(
                {
                    'points': points[istart:iend]    ,
                    'name': pcname,
                    'type': 'pointcloud',
                    'iblk': i+1,
                    'nblk': nblk
                })
            
            print(len(msg), blksize*4*3)
            
            msgs.append(msg)
            
        with self.pc_lock:
        
            self.pc_map[pcname] = msgs
    
    
    @utils.handle_exceptions
    async def visual_get_mesh_handler(self, request):
        uri = request.match_info['uri']
        uri = urllib.parse.unquote(uri)
        print('uri', uri)
        path = ros_utils.resolve_ros_uri(uri)
        if path.startswith('file://'):
            path = path[len('file://'):]
        print('URI/PATH: ', uri, path)
        return web.FileResponse(path)

    @utils.handle_exceptions
    async def visual_get_environment_entities(self, request):
        """
        Estrae elementi statici dell'environment dal URDF.
        Cerca link con joint fixed che non fanno parte della catena cinematica del robot.
        """
        # parse urdf
        urdf = ros_handle.get_urdf()
        urdf = urdf.replace('<texture/>', '')
        model = urdf_parser.Robot.from_xml_string(urdf)

        # Funzione per calcolare trasformazione da world a un link
        def get_transform_to_world(link_name):
            transforms = []
            current = link_name
            
            while current != 'world':
                parent_joint = None
                for joint in model.joints:
                    if joint.child == current:
                        parent_joint = joint
                        break
                
                if parent_joint is None:
                    break
                    
                if parent_joint.origin:
                    transforms.append((list(parent_joint.origin.xyz), list(parent_joint.origin.rpy)))
                else:
                    transforms.append(([0, 0, 0], [0, 0, 0]))
                    
                current = parent_joint.parent
            
            if not transforms:
                return [0, 0, 0], R.from_euler('xyz', [0, 0, 0])
                
            transforms.reverse()
            cumulative_xyz = [0, 0, 0]
            cumulative_rot = R.from_euler('xyz', [0, 0, 0])
            
            for t_xyz, t_rpy in transforms:
                rotated_xyz = cumulative_rot.apply(t_xyz)
                cumulative_xyz = [cumulative_xyz[i] + rotated_xyz[i] for i in range(3)]
                cumulative_rot = cumulative_rot * R.from_euler('xyz', t_rpy)
            
            return cumulative_xyz, cumulative_rot
        
        # Calcola trasformazione da world a base_link
        robot_xyz, robot_rot = get_transform_to_world('base_link')

        # Identifica link dell'environment: quelli collegati direttamente a 'world' tramite joint fixed
        environment_links = set()
        for jname, joint in model.joint_map.items():
            if joint.parent == 'world' and joint.type == 'fixed':
                environment_links.add(joint.child)
        
        # Trova tutti i link collegati agli environment_links tramite joint fixed
        changed = True
        while changed:
            changed = False
            for jname, joint in model.joint_map.items():
                if joint.type == 'fixed':
                    if joint.parent in environment_links and joint.child not in environment_links:
                        environment_links.add(joint.child)
                        changed = True

        # Estrae elementi environment
        env_entities = dict()
        
        for lname, link in model.link_map.items():
            if lname not in environment_links:
                continue
                
            geometries = link.visuals if link.visuals else (link.collisions if link.collision else [])
            
            if not geometries:
                continue
            
            # Calcola trasformazione da world a questo link
            link_xyz, link_rot = get_transform_to_world(lname)
            
            # Processa ogni geometria del link
            for idx, geom_elem in enumerate(geometries):
                local_xyz = list(geom_elem.origin.xyz) if geom_elem.origin else [0, 0, 0]
                local_rpy = list(geom_elem.origin.rpy) if geom_elem.origin else [0, 0, 0]
                
                # Combina trasformazione link + geometria (in world frame)
                local_xyz_rotated = link_rot.apply(local_xyz)
                final_xyz_world = [link_xyz[i] + local_xyz_rotated[i] for i in range(3)]
                final_rot_world = link_rot * R.from_euler('xyz', local_rpy)
                
                # Converti da world frame a base_link frame
                relative_xyz = [final_xyz_world[i] - robot_xyz[i] for i in range(3)]
                relative_xyz = robot_rot.inv().apply(relative_xyz).tolist()
                relative_rot = robot_rot.inv() * final_rot_world
                
                # Assegna colore basato sulla configurazione
                def get_color_for_entity(name):
                    for key, color in self.environment_colors.items():
                        if key in name:
                            return color
                    return self.default_color
                
                origin = {
                    'origin_xyz': relative_xyz,
                    'origin_rot': relative_rot.as_quat().tolist(),
                    'color': get_color_for_entity(lname)
                }
                
                entity_name = f"{lname}_{idx}" if len(geometries) > 1 else lname
                print(f"Environment entity saved: {entity_name}")
                
                if isinstance(geom_elem.geometry, urdf_parser.Mesh):
                    env_entities[entity_name] = {
                        **origin,
                        'type': 'MESH',
                        'filename': geom_elem.geometry.filename,
                        'scale': list(geom_elem.geometry.scale) if geom_elem.geometry.scale else [1, 1, 1],
                    }
                elif isinstance(geom_elem.geometry, urdf_parser.Box):
                    env_entities[entity_name] = {
                        **origin,
                        'type': 'BOX',
                        'filename': '#BOX',
                        'size': [geom_elem.geometry.size[0]*1000,
                                geom_elem.geometry.size[1]*1000,
                                geom_elem.geometry.size[2]*1000],
                        'scale': [0.001, 0.001, 0.001]
                    }
                elif isinstance(geom_elem.geometry, urdf_parser.Cylinder):
                    env_entities[entity_name] = {
                        **origin,
                        'type': 'CYLINDER',
                        'filename': '#CYLINDER',
                        'radius': geom_elem.geometry.radius*1000,
                        'length': geom_elem.geometry.length*1000,
                        'scale': [0.001, 0.001, 0.001]
                    }
                elif isinstance(geom_elem.geometry, urdf_parser.Sphere):
                    env_entities[entity_name] = {
                        **origin,
                        'type': 'SPHERE',
                        'filename': '#SPHERE',
                        'radius': geom_elem.geometry.radius*1000,
                        'scale': [0.001, 0.001, 0.001]
                    }
        
        return web.json_response(env_entities)
    
    @utils.handle_exceptions
    async def visual_get_mesh_entities(self, request):
        
        # parse urdf
        urdf = ros_handle.get_urdf()
        urdf = urdf.replace('<texture/>', '')
        model = urdf_parser.Robot.from_xml_string(urdf)

        # get list of visuals
        visuals = dict()
        for lname, l in model.link_map.items():
            
            if l.collision is None:
                continue

            if l.collision.origin is None:
                origin = {
                    'origin_xyz': [0, 0, 0],
                    'origin_rot': [0, 0, 0, 1]
                }
            else:
                origin = {
                    'origin_xyz': l.collision.origin.xyz,
                    'origin_rot': R.from_euler('xyz', l.collision.origin.rpy).as_quat().tolist()
                }
            
            for c in l.collisions:
                if isinstance(c.geometry, urdf_parser.Mesh):
                    visuals[lname] = {
                        **origin,
                        'type': 'MESH',
                        'filename': c.geometry.filename,
                        'scale': c.geometry.scale,
                    }
                elif isinstance(c.geometry, urdf_parser.Cylinder):
                    visuals[lname] = {
                        **origin,
                        'type': 'CYLINDER',
                        'filename': '#CYLINDER',
                        'radius': c.geometry.radius*1000,
                        'length': c.geometry.length*1000,
                        'scale': [0.001, 0.001, 0.001]
                    }
        
        return web.json_response(visuals)


    # @utils.handle_exceptions
    # async def visual_get_mesh_tfs(self, request: web.Request):

    #     # tf listener
    #     tfl = tf.TransformListener()

    #     # parse urdf
    #     urdf = ros_handle.get_urdf()
    #     urdf = urdf.replace('<texture/>', '')
    #     model = urdf_parser.Robot.from_xml_string(urdf)
    #     root = 'base_link'

    #     # get list of visuals
    #     transforms = dict()
    #     for lname, l in model.link_map.items():
            
    #         for c in l.collisions:
    #             if isinstance(c.geometry, urdf_parser.Mesh):
    #                 await utils.to_thread(tfl.waitForTransform, lname, root, rospy.Time(0), timeout=rospy.Duration(1.0))
    #                 trans, rot = tfl.lookupTransform(root, lname, rospy.Time(0))
    #                 transforms[lname] = [trans, rot]
        
    #     return web.json_response(transforms)



