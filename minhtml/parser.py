"""Simple parser for HTML

Supports conditionals in comments:

Block form (for turning stuff off):
    <!-- !if not variable: -->
        stuff...
    <!-- !endif -->

Comment form (for turning stuff on):
    <!-- !if not variable stuff -->
"""

import sys
import re

from lexer import Token, Lexer

class DOMDoctype(object):
    def __init__(self, doctype):
        self.doctype = doctype

    def toStr(self, params):
        return self.doctype

class DOMComment(object):
    def __init__(self, comment):
        self.comment = comment
        self.cond = None
        self.condId = None
        self.condStr = None
        if comment == '<!-- !endif -->':
            self.cond = 'endif'
        else:
            match = re.match(r'<!-- !if (not )?([a-z]+)(:)?[ \n]+(.*)-->', comment, re.DOTALL)
            if match:
                groups = match.groups()
                if groups[0] is not None:
                    self.cond = 'ifnot'
                else:
                    self.cond = 'if'
                self.condId = groups[1]
                if groups[2] is None:
                    self.condStr = groups[3]

    def toStr(self, params):
        if self.condStr is not None:
            cond = self.condId in params and params[self.condId]
            if self.cond == 'ifnot':
                cond = not cond
            if cond:
                return self.condStr
            else:
                return ''
        elif 'discardComments' in params and params['discardComments']:
            return ''
        else:
            return self.comment

class DOMText(object):
    def __init__(self, text):
        self.text = text

    def toStr(self, params):
        return re.sub(r'\n+', r'\n', self.text)
        #return self.text

class DOMElement(object):
    def __init__(self, tagName, attrs, body):
        self.tagName = tagName
        self.attrs = attrs
        self.body = body

    def toStr(self, params):
        strs = ['<{}'.format(self.tagName)]
        for attr in self.attrs:
            strs.append(' {}={}'.format(attr[0], attr[1]))
        if self.body is None:
            strs.append(' />')
        else:
            strs.append('>')
            strs.append(self.body.toStr(params))
            strs.append('</{}>'.format(self.tagName))
        return ''.join(strs)

class DOMBody(object):
    def __init__(self, items):
        self.items = items

    def toStr(self, params={}):
        strs = []
        keep = True
        for i in xrange(len(self.items)):
            item = self.items[i]
            if isinstance(item, DOMComment) and item.condStr is None:
                if (item.cond == 'if' or item.cond == 'ifnot'):
                    cond = item.condId in params and params[item.condId]
                    if item.cond == 'ifnot':
                        cond = not cond
                    keep = cond
                elif item.cond == 'endif':
                    keep = True
            elif not keep:
                pass
            else:
                strs.append(item.toStr(params))
        return ''.join(strs)

class ParseException(Exception):
    def __init__(self, tok, msg):
        if tok is None:
            self.str = msg
        else:
            self.str = tok.locnStr() + " " + msg

def parseSingleElement(lexer):
    if lexer.isKind(Token.doctype):
        tok = lexer.curToken()
        lexer.nextToken()
        return DOMDoctype(tok.str)

    elif lexer.isKind(Token.comment):
        tok = lexer.curToken()
        lexer.nextToken()
        return DOMComment(tok.str)

    elif lexer.optKind(Token.openStartTag):
        tagName = lexer.getId()
        attrs = []
        body = None

        # parse attributes
        while lexer.isKind(Token.identifier):
            attrName = lexer.getId()
            lexer.getKind(Token.equals)
            attrVal = lexer.getKind(Token.string)
            attrs.append((attrName, attrVal))

        # parse end of tag
        emptyElement = lexer.optKind(Token.forwardSlash)
        lexer.getKind(Token.closeTag)

        if not emptyElement:
            # parse body
            items = []
            while not lexer.isKind(Token.openEndTag):
                item = parseSingleElement(lexer)
                items.append(item)
            body = DOMBody(items)

            # parse closing tag
            tagTok = lexer.curToken()
            lexer.getKind(Token.openEndTag)
            endTagName = lexer.getId()
            lexer.getKind(Token.closeTag)

            if endTagName != tagName:
                raise ParseException(tagTok, "closing tag mismatch, expecting </{}> got </{}>".format(tagName, endTagName))

        return DOMElement(tagName, attrs, body)

    elif lexer.isKind(Token.text):
        # parse text
        tok = lexer.curToken()
        text = []
        while tok.kind == Token.text:
            text.append(tok.str)
            tok = lexer.nextToken()
        return DOMText(''.join(text))

    else:
        raise ParseException(lexer.curToken(), "unexpected")

def parseHTML(fileName):
    fileObj = open(fileName)
    lexer = Lexer(fileName, fileObj)
    items = []
    while not lexer.isEnd():
        item = parseSingleElement(lexer)
        items.append(item)
    fileObj.close()
    return DOMBody(items)

if __name__ == "__main__":
    try:
        body = parseHTML(sys.argv[1])
        sys.stdout.write(body.toStr())
    except ParseException as er:
        sys.stderr.write(str(er) + '\n')
