"""Handling of AMQP connections"""

import json

from .util import typecheck


__all__ = (
    'Message',
)


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
