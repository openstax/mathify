import argparse
import toml
from typing import Callable, Mapping

from . import service
from .config import Config


def start(config, args):
    try:
        service.start(config)
    except KeyboardInterrupt:
        pass


Command = Callable[[Config, Mapping], None]


COMMANDS: Mapping[str, Command] = {
    'enqueue': enqueue,
    'start': start,
}


def main():
    """Main console entry point"""
    argp = argparse.ArgumentParser()
    argp.add_argument('-c', '--config', help="Load configuration file")
    cmds = argp.add_subparsers(title='subcommands', dest='command')

    start = cmds.add_parser('start', help="Start rendering service")

    args = argp.parse_args()

    if args.config:
        raise NotImplementedError()
    else:
        config = Config()

    COMMANDS[args.command](config, args)


if __name__ == '__main__':
    main()
