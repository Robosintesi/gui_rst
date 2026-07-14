import asyncio
from aiohttp import web
import json
import os
import yaml

# ros handle
from . import ros_utils
ros_handle : ros_utils.RosWrapper = ros_utils.ros_handle

from std_srvs.srv import SetBool
from std_msgs.msg import Bool

from .server import ServerBase
from .screen_session import Process
from .ssh_process import SshProcess
from . import utils


class MissionHandler:

    def __init__(self, srv: ServerBase, config=dict()) -> None:

        # config
        self.rate = config.get('rate', 1.0)
        self.pause_service = config.get('pause_service', '/tree_main/pause')
        self.paused_topic = config.get('paused_topic', '/tree_main/paused')

        # the mission process (cmd, machine) is defined in the launcher
        # config file, under the entry named by 'process'
        launcher_cfg_path = config.get('launcher_config', 'launcher_config.yaml')
        if not os.path.isabs(launcher_cfg_path):
            launcher_cfg_path = os.path.join(os.path.dirname(srv.cfgpath), launcher_cfg_path)
        launcher_cfg = yaml.safe_load(open(launcher_cfg_path, 'r'))

        proc_name = config.get('process', 'mission')
        try:
            proc_cfg = launcher_cfg[proc_name]
        except KeyError:
            raise KeyError(f'process "{proc_name}" not found in {launcher_cfg_path}')
        self.machine = proc_cfg.get('machine', 'localhost')

        # mission process on the target machine; 'tmux' runs it in a
        # tmux session over ssh (survives server restarts, requires tmux
        # on the target), 'ssh' runs it inside a plain ssh connection
        # held by this server (no tmux needed, dies with the server)
        mode = proc_cfg.get('mode', config.get('mode', 'tmux'))
        if mode == 'ssh':
            self.proc = SshProcess(name=proc_name,
                                   cmd=proc_cfg['cmd'],
                                   machine=self.machine)
        elif mode == 'tmux':
            self.proc = Process(name=proc_name,
                                cmd=proc_cfg['cmd'],
                                machine=self.machine)
        else:
            raise ValueError(f'invalid mission mode "{mode}" (use "tmux" or "ssh")')

        # paused state, kept in sync with the executor's latched topic
        self.paused = False
        self.paused_sub = ros_handle.create_subscription(
            Bool, self.paused_topic, self.on_paused_recv, 1, latch=True)

        # save server object, register our handlers
        self.srv = srv
        self.srv.add_route('POST', '/mission/start', self.start_handler, 'mission_start')
        self.srv.add_route('POST', '/mission/stop', self.stop_handler, 'mission_stop')
        self.srv.add_route('POST', '/mission/set_paused', self.set_paused_handler, 'mission_set_paused')
        self.srv.add_route('GET', '/mission/state', self.state_handler, 'mission_state')

        self.srv.schedule_task(self.run())


    def on_paused_recv(self, msg: Bool):
        self.paused = msg.data


    def mission_status(self, running):
        if not running:
            self.paused = False
        return {
            'type': 'mission_status',
            'running': running,
            'paused': self.paused,
        }


    @utils.handle_exceptions
    async def start_handler(self, request: web.Request):
        ok = await self.proc.start()
        return web.Response(text=json.dumps({
            'success': ok,
            'message': f'mission {"started" if ok else "failed to start"} on {self.machine}',
            }))


    @utils.handle_exceptions
    async def stop_handler(self, request: web.Request):
        # ctrl+c to the mission tmux session
        ok = await self.proc.stop()
        return web.Response(text=json.dumps({
            'success': ok,
            'message': f'mission {"stopped" if ok else "failed to stop"} on {self.machine}',
            }))


    @utils.handle_exceptions
    async def set_paused_handler(self, request: web.Request):
        paused = utils.str2bool(request.rel_url.query['paused'])
        pause = ros_handle.create_client(SetBool, self.pause_service)
        res = await ros_handle.call(pause, timeout_sec=1, data=paused)
        return web.Response(text=json.dumps({
            'success': res.success,
            'message': res.message,
            'paused': paused,
            }))


    @utils.handle_exceptions
    async def state_handler(self, request: web.Request):
        running = (await self.proc.status()) == 'Running'
        return web.Response(text=json.dumps({
            'success': True,
            **self.mission_status(running),
            }))


    async def run(self):

        while True:

            await asyncio.sleep(1./self.rate)

            try:
                running = (await self.proc.status()) == 'Running'

                await self.srv.ws_send_to_all(json.dumps(self.mission_status(running)))
            except BaseException as e:
                print(f'[mission] status broadcast failed: {e.__class__.__name__} {e}')
