import io
import logging
import shlex
import subprocess
import yaml
from typing import List


__all__ = (
    'Plan',
)


log = logging.getLogger(__name__)


class Plan:
    """Execution plan; an ordered list of steps"""

    @classmethod
    def read(cls, path):
        """Read execution plan from a file or a file-like object"""
        if isinstance(path, io.IOBase):
            desc = yaml.load(path)
        else:
            with open(path, 'r') as src:
                desc = yaml.load(src)

        steps = list(map(shlex.split, desc['steps']))

        return cls(steps=steps)

    @classmethod
    def default(cls):
        """Load default execution plan bundled with this package"""
        import pkg_resources
        return cls.read(pkg_resources.resource_stream('bakedpdf', 'plan.yml'))

    def __init__(self, *, steps):
        self.steps = steps

    def __iter__(self):
        return iter(self.steps)

    def execute(self, *, log=None):
        """Execute this plan"""
        return Executor(self, log=log).start()


def expand_env(command: List[str], env) -> List[str]:
    """Expand environment variables (``$VAR_NAME``) into its value.

    Unlike in classic shells expanded variables are not re-parsed. That is, even
    if there are spaces in value it will not be split into multiple arguments,
    or in other words ``$VAR_NAME`` here is equivalent to ``"$VAR_NAME"``
    in sh.

    Also, currently only standalone variables will be expanded; ``$VAR`` in
    ``prefix$VAR`` will not be expanded.
    """
    def replace(item):
        if item.startswith('$'):
            return env.get(item[1:], '')
        return item

    return list(map(replace, command))


class ExecutionError(Exception):
    """Command did not complete successfully."""
    def __init__(self, code, command):
        super().__init__("Command returned {}: {}".format(
            code,
            ' '.join(map(shlex.quote, command)),
        ))


class Executor:
    def __init__(self, plan: Plan, *, log=None):
        self.plan = plan
        # TODO: what needs to be in env?
        self.env = {}
        self.log = log
        """File to log output to. When ``None`` output will not be captured."""

    def start(self):
        """Start execution of a plan with current settings"""
        for step in self.plan:
            self.step(step)

    def step(self, step):
        """Process a single step of a plan"""
        command = expand_env(step, self.env)

        if self.log:
            out, err = self.log, subprocess.STDOUT
        else:
            out, err = None, None

        p = subprocess.Popen(
            command,
            stdout=out,
            stderr=err,
            env=self.env,
        )

        code = p.wait()

        if code != 0:
            raise ExecutionError(code, command)
