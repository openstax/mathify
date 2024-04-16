import sys
from subprocess import Popen, PIPE
from shlex import split
import select
from time import sleep
import traceback
from pathlib import Path


def _pipe_next(p, item, timeout=5):
    lines = item.split("\n")
    for line in lines:
        p.stdin.write(line)
        p.stdin.write("\n")
    ready_to_read, _, _ = select.select([p.stdout], [], [], timeout)
    if not ready_to_read:
        # Do not rise here because that would interrupt the generator
        return Exception("Timeout while waiting for process response")
    return "\n".join(p.stdout.readline().strip() for _ in lines)


def pipe_to(p, pipe_handler):
    item = yield None
    while not p.poll():
        item = yield pipe_handler(p, item)


def create_one_to_one_pipe(p):
    while not p.stdin.writable() or not p.stdout.readable():
        sleep(0.1)
    pipe = pipe_to(p, _pipe_next)
    next(pipe)  # Prime the generator (required step)
    return pipe


class ProcessPipe:
    def __init__(self, command, *, stderr=sys.stderr):
        self.proc = Popen(
            split(command),
            stdin=PIPE,
            stdout=PIPE,
            stderr=stderr,
            bufsize=0,
            encoding="utf-8",
        )
        self.pipe = create_one_to_one_pipe(self.proc)

    def send(self, line: str):
        response = self.pipe.send(line)
        if response is None:
            return None
        # Raise here instead
        if isinstance(response, Exception):
            raise response
        return response

    def close(self):
        assert self.proc.stdin is not None
        self.proc.stdin.close()
        return self.proc.wait()


class Mathify(ProcessPipe):
    def __init__(self, path_to_typeset, *, stderr=sys.stderr):
        start_path = Path(path_to_typeset) / "start.js"
        assert start_path.exists(), f"Path does not exist: {start_path}"
        command = f"node {start_path} -I -i - -f mathml -q"
        super().__init__(command, stderr=stderr)
    
    def send(self, line: str):
        response = super().send(line)
        if isinstance(response, str) and response.startswith("Error:"):
            raise Exception(response)
        return response


pipe = Mathify("./typeset")
for p in Path("..").glob("**/content.json"):
    try:
        print(pipe.send(str(p)), file=sys.stderr)
    except Exception as e:
        for e in traceback.format_exception(e):
            print(e, file=sys.stderr)
        sys.exit(111)
pipe.close()
