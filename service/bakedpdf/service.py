import logging

from .config import Config
from .connection import Connection, Message
from .executor import Plan


log = logging.getLogger(__name__)


def connect(config: Config) -> Connection:
    c = config.amqp
    return Connection(host=c.host, port=c.port, queue=c.queue)


def enqueue(config: Config, *, source: str):
    """Enqueue a job"""
    with connect(config) as connection:
        message = Message(source=source)
        connection.send(message)


def start(config: Config):
    """Start rendering service"""
    Service(config).spin()


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
            log.info('Ready to accept messages')
            for message in connection.listen():
                log.info('Received message: %s', message)
                self.process(message)
