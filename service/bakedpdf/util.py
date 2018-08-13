import functools
import inspect
import itertools


def typecheck(func):
    sig = inspect.getfullargspec(func)

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        for name, arg in itertools.chain(zip(sig.args, args), kwargs.items()):
            try:
                ty = sig.annotations[name]
            except KeyError:
                continue

            if not isinstance(arg, ty):
                raise TypeError(
                    "'{}' is not a valid type for '{}', expected an "
                    "instance of '{}'"
                    .format(type(arg).__qualname__, name, ty.__qualname__)
                )

        return func(*args, **kwargs)

    return wrapper
