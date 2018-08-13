import pytest

from bakedpdf.config import _ConfigBase


class C(_ConfigBase):
    f1: int = 2
    f2: str


def test_missing_key():
    with pytest.raises(ValueError) as ex:
        test = C(f1=2)
    assert "Missing required key: f2" in str(ex)


def test_extra_key():
    with pytest.raises(ValueError) as ex:
        test = C(f1=2, f2='test', f3=True)
    assert "Unexpected key: f3" in str(ex)


def test_wrong_type():
    with pytest.raises(ValueError) as ex:
        test = C(f1=2, f2=3)
    assert "Invalid type for f2: expected 'str' not 'int'" in str(ex)


def test_correct():
    test = C(f1=1, f2='test')
    assert test.f1 == 1
    assert test.f2 == 'test'
    assert vars(test).keys() == {'f1', 'f2'}


def test_default():
    test = C(f2='hello')
    assert test.f1 == 2
    assert test.f2 == 'hello'
    assert vars(test).keys() == {'f1', 'f2'}


class C2(_ConfigBase):
    f3: int
    f4: C


def test_nested():
    test = C2({
        'f3': 2,
        'f4': {
            'f1': 3,
            'f2': 'test',
        },
    })
    assert test.f3 == 2
    assert test.f4.f1 == 3
    assert test.f4.f2 == 'test'
    assert vars(test).keys() == {'f3', 'f4'}
    assert vars(test.f4).keys() == {'f1', 'f2'}


class C3(_ConfigBase):
    f: int = 2


class C4(_ConfigBase):
    f1: str = 'test'
    f2: C3


def test_nested_default():
    test = C4()
    assert test.f1 == 'test'
    assert test.f2.f == 2
    assert vars(test).keys() == {'f1', 'f2'}
    assert vars(test.f2).keys() == {'f'}
