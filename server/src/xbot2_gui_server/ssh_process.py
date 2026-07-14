import asyncio


class SshProcess:

    def __init__(self, name, cmd, machine):
        self.name = name
        self.cmd = cmd
        self.hostname = machine
        self.proc: asyncio.subprocess.Process = None

    async def start(self, options=None):

        if self._alive():
            return True

        # bash -ic loads the remote user's .bashrc (ros env, etc.);
        # output is duplicated to /tmp for post-mortem inspection
        cmd = (f'bash -ic "{self.cmd} '
               f'1> >(tee /tmp/{self.name}.stdout) '
               f'2> >(tee /tmp/{self.name}.stderr >&2)"')

        print(f'[{self.name}] executing command: ssh -tt {self.hostname} {cmd}')

        self.proc = await asyncio.create_subprocess_exec(
            '/usr/bin/ssh', '-tt', self.hostname, cmd,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT)

        asyncio.get_running_loop().create_task(self._drain_output(self.proc))

        try:
            await asyncio.wait_for(self.proc.wait(), 2.0)
        except asyncio.TimeoutError:
            print(f'[{self.name}] process started on {self.hostname}')
            return True

        print(f'[{self.name}] process exited immediately '
              f'with code {self.proc.returncode}')
        return False

    async def stop(self):

        if not self._alive():
            print(f'[{self.name}] no process to stop')
            return False

        # ctrl+C through the remote tty
        try:
            self.proc.stdin.write(b'\x03')
            await self.proc.stdin.drain()
        except (ConnectionError, BrokenPipeError):
            pass

        print(f'[{self.name}] sent ctrl+c to remote process')
        return True

    async def kill(self):

        if not self._alive():
            return False

        self.proc.kill()
        print(f'[{self.name}] killed ssh connection (remote gets SIGHUP)')
        return True

    async def status(self):
        return 'Running' if self._alive() else 'Stopped'

    def _alive(self):
        return self.proc is not None and self.proc.returncode is None

    async def _drain_output(self, proc):
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            print(f'[{self.name}] {line.decode(errors="replace").rstrip()}')
