import asyncio
from aiohttp import web
import json
import os
import yaml

# ros handle
from . import ros_utils
ros_handle : ros_utils.RosWrapper = ros_utils.ros_handle

from std_srvs.srv import SetBool
from std_msgs.msg import Bool, String

from .server import ServerBase
from . import utils


class MissionHandler:

    def __init__(self, srv: ServerBase, config=dict()) -> None:

        # config
        self.rate = config.get('rate', 1.0)
        self.pause_service = config.get('pause_service', '/tree_main/pause')
        self.paused_topic = config.get('paused_topic', '/tree_main/paused')
        self.progress_topic = config.get('progress_topic', '/mission_progress')

        self.launcher_cfg_path = config.get('launcher_config', 'launcher_config.yaml')
        if not os.path.isabs(self.launcher_cfg_path):
            self.launcher_cfg_path = os.path.join(os.path.dirname(srv.cfgpath), self.launcher_cfg_path)

        self.mission_process = config.get('process', 'mission')
        self.scenario_variant = config.get('variant', 'scenario')

        # paused state, kept in sync with the executor's latched topic
        self.paused = False
        self.paused_sub = ros_handle.create_subscription(
            Bool, self.paused_topic, self.on_paused_recv, 1, latch=True)

        self.progress = None
        self.progress_sub = ros_handle.create_subscription(
            String, self.progress_topic, self.on_progress_recv, 1, latch=True)

        # save server object, register our handlers
        self.srv = srv
        self.srv.add_route('POST', '/mission/set_paused', self.set_paused_handler, 'mission_set_paused')
        self.srv.add_route('GET', '/mission/state', self.state_handler, 'mission_state')
        self.srv.add_route('GET', '/mission/scenarios', self.scenarios_handler, 'mission_scenarios')

        self.srv.schedule_task(self.run())


    def load_scenarios(self):

        try:
            with open(self.launcher_cfg_path, 'r') as f:
                cfg = yaml.safe_load(f) or {}
        except (OSError, yaml.YAMLError) as e:
            print(f'[mission] cannot read {self.launcher_cfg_path}: {e}')
            return []

        variants = (cfg.get(self.mission_process) or {}).get('variants') or {}
        choices = variants.get(self.scenario_variant)

        if isinstance(choices, list):
            entries = [(list(c.keys())[0], list(c.values())[0] or {}) for c in choices]
        elif isinstance(choices, dict):
            entries = [(self.scenario_variant, choices)]
        else:
            entries = []

        return [
            {
                'name': name,
                'label': entry.get('label', name),
                'info': entry.get('info', ''),
            }
            for name, entry in entries
        ]


    def on_paused_recv(self, msg: Bool):
        self.paused = msg.data


    def on_progress_recv(self, msg: String):
        try:
            self.progress = json.loads(msg.data)
        except ValueError as e:
            print(f'[mission] bad progress payload: {e}')


    def mission_status(self):
        status = {
            'type': 'mission_status',
            'paused': self.paused,
        }

        if self.progress is not None:
            status['progress'] = self.progress

        return status


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
    async def scenarios_handler(self, request: web.Request):
        scenarios = self.load_scenarios()
        return web.Response(text=json.dumps({
            'success': True,
            'message': f'got {len(scenarios)} scenario(s) of process {self.mission_process}',
            'process': self.mission_process,
            'variant': self.scenario_variant,
            'scenarios': scenarios,
            }))


    @utils.handle_exceptions
    async def state_handler(self, request: web.Request):
        return web.Response(text=json.dumps({
            'success': True,
            **self.mission_status(),
            }))


    async def run(self):

        while True:

            await asyncio.sleep(1./self.rate)

            try:
                await self.srv.ws_send_to_all(json.dumps(self.mission_status()))
            except BaseException as e:
                print(f'[mission] status broadcast failed: {e.__class__.__name__} {e}')
