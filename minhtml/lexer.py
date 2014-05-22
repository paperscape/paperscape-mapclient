"""Simple tokeniser for XML/HTML"""

class Token:
    invalid = 'invalid'
    end = 'end'
    text = 'text'
    openStartTag = 'open start tag'
    openEndTag = 'open end tag'
    closeTag = 'close tag'
    forwardSlash = 'forward slash'
    equals = 'equals'
    identifier = 'identifier'
    string = 'string'
    doctype = 'doctype'
    comment = 'comment'

    @classmethod
    def fromSrc(cls, srcName, srcLine, srcColumn):
        return cls(Token.invalid, '', srcName, srcLine, srcColumn)

    def __init__(self, kind, st, srcName, srcLine, srcColumn):
        self.kind = kind
        self.str = st
        self.srcName = srcName
        self.srcLine = srcLine
        self.srcColumn = srcColumn

    def __str__(self):
        if self.kind == Token.invalid:
            return '(invalid)'
        elif self.kind == Token.end:
            return '(end)'
        else:
            return self.str

    def locnStr(self):
        return '(' + str(self.srcName) + ':' + str(self.srcLine) + ':' + str(self.srcColumn) + ')'

    def isEnd(self):
        return self.kind == Token.end

    def isIdStr(self, str):
        return self.kind == Token.identifier and self.str == str

def charIsIdHead(ch):
    return ch.isalpha() or ch in ':_'

def charIsIdTail(ch):
    return ch.isalnum() or ch in ':_-.'

class Lexer:
    def __init__(self, srcName, fileObj):
        self.__name = srcName
        self.__file = fileObj
        self.__curCharBuf = self.__readChar()
        self.__nextCharBuf = self.__readChar()
        self.__line = 1
        self.__column = 1
        self.__curToken = None
        self.__inTag = False
        self.nextToken()

    def __readChar(self):
        return self.__file.read(1)

    def __curChar(self):
        return self.__curCharBuf

    def __nextChar(self):
        c = self.__curCharBuf
        if c == '':
            return c
        elif c == '\n':
            self.__line += 1
            self.__column = 1
        elif c == '\t':
            self.__column += 8
        else:
            self.__column += 1
        self.__curCharBuf = self.__nextCharBuf
        self.__nextCharBuf = self.__readChar()
        return self.__curChar()

    def curToken(self):
        return self.__curToken

    def nextToken(self):
        # get the first character of the token
        ch = self.__curChar()

        if self.__inTag:
            # skip white space
            while ch.isspace():
                ch = self.__nextChar()

        # create the token object
        tok = Token.fromSrc(self.__name, self.__line, self.__column)

        if ch == '':
            # end of stream token
            tok.kind = Token.end

        elif ch == '<':
            # open tag
            tok.str = ch
            ch = self.__nextChar()
            if self.__inTag:
                tok.kind = Token.invalid
            else:
                tok.kind = Token.openStartTag
                self.__inTag = True

            if tok.kind == Token.openStartTag and ch == '/':
                # opening of an end tag
                tok.str = '</'
                tok.kind = Token.openEndTag
                self.__nextChar()

            elif tok.kind == Token.openStartTag and ch == '!':
                # a special tag
                chs = [tok.str, ch]
                ch = self.__nextChar()
                if ch == 'D':
                    lookAhead = 7
                elif ch == '-':
                    lookAhead = 2
                else:
                    lookAhead = 0
                for i in xrange(lookAhead):
                    chs.append(ch)
                    ch = self.__nextChar()
                tok.str = ''.join(chs)

                if tok.str.upper() == '<!DOCTYPE':
                    # doctype
                    chs = []
                    while ch != '' and ch != '>':
                        chs.append(ch)
                        ch = self.__nextChar()
                    chs.append(ch)
                    self.__nextChar()
                    tok.str += ''.join(chs)
                    if tok.str[-1] == '>':
                        tok.kind = Token.doctype
                        self.__inTag = False
                    else:
                        tok.kind = Token.invalid

                elif tok.str == '<!--':
                    # comment
                    chs = []
                    while ch != '' and not (len(chs) >= 2 and chs[-2] == '-' and chs[-1] == '-'):
                        chs.append(ch)
                        ch = self.__nextChar()
                    chs.append(ch)
                    self.__nextChar()
                    tok.str += ''.join(chs)
                    if tok.str[-1] == '>':
                        tok.kind = Token.comment
                        self.__inTag = False
                    else:
                        tok.kind = Token.invalid

                else:
                    tok.kind = Token.invalid

        elif ch == '>':
            # close tag
            tok.str = ch
            ch = self.__nextChar()
            if not self.__inTag:
                tok.kind = Token.invalid
            else:
                tok.kind = Token.closeTag
                self.__inTag = False

        elif not self.__inTag:
            # normal text outside a tag
            tok.kind = Token.text
            tok.str = ch
            self.__nextChar()

        elif ch in '/':
            # forward slash
            tok.kind = Token.forwardSlash
            tok.str = ch
            ch = self.__nextChar()

        elif ch in '=':
            # equals
            tok.kind = Token.equals
            tok.str = ch
            ch = self.__nextChar()

        elif charIsIdHead(ch):
            # an identifier
            tok.kind = Token.identifier
            chs = []
            while charIsIdTail(ch):
                chs.append(ch)
                ch = self.__nextChar()
            tok.str = ''.join(chs)

        elif ch in '\'"':
            # string
            tok.kind = Token.string
            chs = [ch]
            ch2 = self.__nextChar()
            while ch2 != '' and ch2 != ch:
                chs.append(ch2)
                if ch2 == '\\':
                    chs.append(self.__nextChar())
                ch2 = self.__nextChar()
            chs.append(ch2)
            self.__nextChar()
            tok.str = ''.join(chs)

        else:
            # invalid/unknown character
            tok.kind = Token.invalid
            tok.str = ch
            self.__nextChar()

        self.__curToken = tok
        return tok

    def isEnd(self):
        return self.__curToken.kind == Token.end

    def isKind(self, kind):
        return self.__curToken.kind == kind

    def optKind(self, kind):
        if self.__curToken.kind == kind:
            self.nextToken()
            return True
        else:
            return False

    def error(self, msg):
        raise Exception(self.__curToken().locnStr() + " " + msg)

    def getKind(self, kind):
        if self.__curToken.kind != kind:
            self.error("expecting {}".format(kind))
        tok = self.__curToken
        self.nextToken()
        return tok

    def getId(self):
        if self.__curToken.kind != Token.identifier:
            self.error("expecting an identifier")
        id = self.__curToken.str
        self.nextToken()
        return id

