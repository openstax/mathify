"""Handling of AMQP connections"""

import json
import logging
import pika

from .util import typecheck


__all__ = (
    'Connection',
    'Message',
)


log = logging.getLogger(__name__)


class MessageDecodeError(Exception):
    """Exception raised when a :class:`Message` can't be decoded form
    a byte stream.
    """
    def __init__(self):
        super().__init__("Message could not be decoded")


class Message:
    @classmethod
    def decode(cls, data: bytes):
        """Decode a message from its wire representation"""
        try:
            fields = json.loads(data)
            return cls(**fields)
        except (json.JSONDecodeError, TypeError) as ex:
            raise MessageDecodeError() from ex

    @typecheck
    def __init__(self, *, source: str):
        self.source = source

    def __repr__(self):
        return '<Message source={!r}>'.format(self.source)

    def __eq__(self, other):
        return isinstance(other, Message) and self.source == other.source

    def encode(self) -> bytes:
        """Transform a message into its wire representation"""
        return json.dumps({
            'source': self.source,
        })


class Connection:
    """Wrapper around an AMQP connection, a channel, and a queue"""

    def __init__(self, *, host, port, queue):
        params = pika.ConnectionParameters(host, port)
        self.connection = pika.BlockingConnection(params)
        self.channel = self.connection.channel()
        self.channel.queue_declare(queue=queue)
        self.channel.confirm_delivery()
        self.queue = queue

    def __enter__(self, *args):
        return self

    def __exit__(self, *args):
        self.close()

    def close(self):
        """Close the connection"""
        self.connection.close()

    def listen(self):
        """Listen for incoming messages"""
        try:
            for method, props, body in self.channel.consume(self.queue):
                try:
                    message = Message.decode(body)
                except MessageDecodeError:
                    # Omitting reject=False will cause RabbitMQ to put
                    # the message _at the front_ of the queue, which means
                    # it will instantly be re-delivered to us, causing us to
                    # spin forever rejecting the same message.
                    self.channel.basic_reject(method.delivery_tag, requeue=False)
                    log.exception('Invalid message received')
                    continue

                yield message

                self.channel.basic_ack(method.delivery_tag)

        finally:
            pass

    def send(self, message: Message):
        """Send a single message"""
        self.channel.basic_publish('', self.queue, message.encode())
