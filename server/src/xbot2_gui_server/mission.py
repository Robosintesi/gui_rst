import asyncio
from aiohttp import web
import json

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

        self.srv.schedule_task(self.run())


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
