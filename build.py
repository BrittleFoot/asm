"""
    Нужды сборки.
    Пока что необходимость была только в очистке 
    директории от всего, что не исходники :)

"""

import argparse
import os
import sys
import glob
from os import path, walk


def main_clean(args):

    files = glob.glob('*.lst') + glob.glob('*.map') + glob.glob('*.obj')
    if args.clean_com:
        files += glob.glob('*.com')

    list(map(os.remove, files))

    print('%s files deleted!' % len(files))
    print(files, file=sys.stderr)


def parse_args():
    parser = argparse.ArgumentParser()
    subp = parser.add_subparsers(dest='action')
    subp.required = True

    p_clean = subp.add_parser('clean', help='clean build directory')
    p_clean.add_argument(
        '--clean-com', '-c',
        help='also clean executable files',
        action='store_true')
    p_clean.set_defaults(func='clean')

    return parser.parse_args()


def main():
    functions = {
        'clean': main_clean,
    }

    args = parse_args()
    func = functions[args.func]
    func(args)


if __name__ == '__main__':
    main()
