import collections


class _ConfigBase:
    def __init__(self, *args, **kwargs):
        if args and kwargs:
            raise ValueError()

        if len(args) > 1:
            raise ValueError("Expected a single argument")

        if args:
            kwargs = args[0]

        if not isinstance(kwargs, collections.MutableMapping):
            raise TypeError("Expected a mapping")

        for name, ty in self.__annotations__.items():
            try:
                value = kwargs.pop(name)
            except KeyError:
                if hasattr(type(self), name):
                    setattr(self, name, getattr(type(self), name))
                    continue
                if issubclass(ty, _ConfigBase):
                    setattr(self, name, ty())
                    continue
                raise ValueError("Missing required key: " + name) from None

            if issubclass(ty, _ConfigBase):
                value = ty(value)

            if not isinstance(value, ty):
                raise ValueError("Invalid type for {}: expected '{}' not '{}'"
                    .format(name, ty.__qualname__, type(value).__qualname__))

            setattr(self, name, value)

        if kwargs:
            name, value = kwargs.popitem()
            raise ValueError("Unexpected key: " + name)

    def __repr__(self):
        return '<Configuration {}>'.format(' '.join(
            '{}={!r}'.format(name, getattr(self, name))
            for name in self.__annotations__.keys()
        ))


class AmqpConfig(_ConfigBase):
    host: str = 'localhost'
    port: int = 5672
    queue: str = 'bakedpdf:incoming'


class Config(_ConfigBase):
    amqp: AmqpConfig
