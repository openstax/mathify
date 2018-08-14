from .config import Config
from .connection import Connection, Message
from .executor import Plan


def connect(config: Config) -> Connection:
    c = config.amqp
    return Connection(host=c.host, port=c.port, queue=c.queue)


class Service:
    def __init__(self, config: Config):
        self.config = config
        self.plan = Plan.default()

    def process(self, message: Message):
        """Process a single message"""
        # TODO: prepare a temp directory for worker
        # TODO: acquire input
        # TODO: pass input to plan
        self.plan.execute()
        # TODO: handle exceptions

    def spin(self):
        with connect(self.config) as connection:
            for message in connection.listen():
                self.process(message)
