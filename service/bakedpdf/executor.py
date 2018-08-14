import io
import shlex
import subprocess
import yaml
from typing import List

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

    def execute(self):
        """Execute this plan"""
        return Executor(self).start()


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


class Executor:
    def __init__(self, plan: Plan):
        self.plan = plan
        # TODO: what needs to be in env?
        self.env = {}

    def start(self):
        """Start execution of a plan with current settings"""
        for step in self.plan:
            self.step(step)

    def step(self, step):
        """Process a single step of a plan"""
        command = expand_env(step, self.env)
        p = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=self.env,
        )
        out, err = p.communicate()
