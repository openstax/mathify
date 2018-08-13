import json
import pytest

from bakedpdf import Message, connection


def test_decode_invalid_messages():
    with pytest.raises(connection.MessageDecodeError):
        Message.decode('not a JSON')


def test_decode_incorrect_field_type():
    with pytest.raises(connection.MessageDecodeError) as ex:
        Message.decode('{"source":12}')
    assert "'int' is not a valid type for 'source'" in str(ex.value.__cause__)


def test_decode_missing_required_field():
    with pytest.raises(connection.MessageDecodeError) as ex:
        Message.decode('{}')
    assert 'missing 1 required keyword-only argument' in str(ex.value.__cause__)


def test_decode_correct_message():
    msg = Message.decode('{"source":"src"}')
    assert isinstance(msg, Message)
    assert msg.source == 'src'


def test_encode_message():
    m1 = Message(source='src')
    m2 = Message.decode(m1.encode())
    assert m1 == m2
