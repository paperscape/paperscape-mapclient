"""Minify HTML
A quick hack at the moment.
"""

import sys
import argparse

from parser import parseHTML, ParseException

def doMin(fileName):
    body = parseHTML(fileName)
    sys.stdout.write(body.toStr({'discardComments':True, 'deploy':True}))

if __name__ == "__main__":

    cmdParser = argparse.ArgumentParser(description='Minify HTML')
    cmdParser.add_argument('files', nargs=1, help='input file')
    args = cmdParser.parse_args()

    try:
        doMin(args.files[0])
    except ParseException as er:
        sys.stderr.write(str(er) + '\n')
