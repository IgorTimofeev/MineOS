import re
import sys
from numbers import Number

import six

ERRORS = {
    'unexp_end_string': u'Unexpected end of string while parsing Lua string.',
    'unexp_end_table': u'Unexpected end of table while parsing Lua string.',
    'mfnumber_minus': u'Malformed number (no digits after initial minus).',
    'mfnumber_dec_point': u'Malformed number (no digits after decimal point).',
    'mfnumber_sci': u'Malformed number (bad scientific format).',
}


class ParseError(Exception):
    pass


class SLPP(object):

    def __init__(self):
        self.text = ''
        self.ch = ''
        self.at = 0
        self.len = 0
        self.depth = 0
        self.space = re.compile('\s', re.M)
        self.alnum = re.compile('\w', re.M)
        self.newline = '\n'
        self.tab = '\t'

    def decode(self, text):
        if not text or not isinstance(text, six.string_types):
            return
        # FIXME: only short comments removed
        reg = re.compile('--.*$', re.M)
        text = reg.sub('', text, 0)
        self.text = text
        self.at, self.ch, self.depth = 0, '', 0
        self.len = len(text)
        self.next_chr()
        result = self.value()
        return result

    def encode(self, obj):
        self.depth = 0
        return self.__encode(obj)

    def __encode(self, obj):
        s = ''
        tab = self.tab
        newline = self.newline

        if isinstance(obj, str):
            s += '"%s"' % obj.replace(r'"', r'\"')
        elif six.PY2 and isinstance(obj, unicode):
            s += '"%s"' % obj.encode('utf-8').replace(r'"', r'\"')
        elif six.PY3 and isinstance(obj, bytes):
            s += '"{}"'.format(''.join(r'\x{:02x}'.format(c) for c in obj))
        elif isinstance(obj, bool):
            s += str(obj).lower()
        elif obj is None:
            s += 'nil'
        elif isinstance(obj, Number):
            s += str(obj)
        elif isinstance(obj, (list, tuple, dict)):
            self.depth += 1
            if len(obj) == 0 or (not isinstance(obj, dict) and len([
                    x for x in obj
                    if isinstance(x, Number) or (isinstance(x, six.string_types) and len(x) < 10)
               ]) == len(obj)):
                newline = tab = ''
            dp = tab * self.depth
            s += "%s{%s" % (tab * (self.depth - 2), newline)
            if isinstance(obj, dict):
                contents = []
                all_keys_int = all(isinstance(k, int) for k in obj.keys())
                for k, v in obj.items():
                    if all_keys_int:
                        contents.append(self.__encode(v))
                    else:
                        contents.append(dp + '["%s"] = %s' % (k, self.__encode(v)))
                s += (',%s' % newline).join(contents)

            else:
                s += (',%s' % newline).join(
                    [dp + self.__encode(el) for el in obj])
            self.depth -= 1
            s += "%s%s}" % (newline, tab * self.depth)
        return s

    def white(self):
        while self.ch:
            if self.space.match(self.ch):
                self.next_chr()
            else:
                break

    def next_chr(self):
        if self.at >= self.len:
            self.ch = None
            return None
        self.ch = self.text[self.at]
        self.at += 1
        return True

    def value(self):
        self.white()
        if not self.ch:
            return
        if self.ch == '{':
            return self.object()
        if self.ch == "[":
            self.next_chr()
        if self.ch in ['"',  "'",  '[']:
            return self.string(self.ch)
        if self.ch.isdigit() or self.ch == '-':
            return self.number()
        return self.word()

    def string(self, end=None):
        s = ''
        start = self.ch
        if end == '[':
            end = ']'
        if start in ['"',  "'",  '[']:
            while self.next_chr():
                if self.ch == end:
                    self.next_chr()
                    if start != "[" or self.ch == ']':
                        return s
                if self.ch == '\\' and start == end:
                    self.next_chr()
                    if self.ch != end:
                        s += '\\'
                s += self.ch
        raise ParseError(ERRORS['unexp_end_string'])

    def object(self):
        o = {}
        k = None
        idx = 0
        numeric_keys = False
        self.depth += 1
        self.next_chr()
        self.white()
        if self.ch and self.ch == '}':
            self.depth -= 1
            self.next_chr()
            return o  # Exit here
        else:
            while self.ch:
                self.white()
                if self.ch == '{':
                    o[idx] = self.object()
                    idx += 1
                    continue
                elif self.ch == '}':
                    self.depth -= 1
                    self.next_chr()
                    if k is not None:
                        o[idx] = k
                    if not numeric_keys and len([key for key in o if isinstance(key, six.string_types + (float,  bool, tuple))]) == 0:
                        ar = []
                        for key in o:
                            ar.insert(key, o[key])
                        o = ar
                    return o  # or here
                else:
                    if self.ch == ',':
                        self.next_chr()
                        continue
                    else:
                        k = self.value()
                        if self.ch == ']':
                            numeric_keys = True
                            self.next_chr()
                    self.white()
                    ch = self.ch
                    if ch in ('=', ','):
                        self.next_chr()
                        self.white()
                        if ch == '=':
                            o[k] = self.value()
                        else:
                            o[idx] = k
                        idx += 1
                        k = None
        raise ParseError(ERRORS['unexp_end_table'])  # Bad exit here

    words = {'true': True, 'false': False, 'nil': None}
    def word(self):
        s = ''
        if self.ch != '\n':
            s = self.ch
        self.next_chr()
        while self.ch is not None and self.alnum.match(self.ch) and s not in self.words:
            s += self.ch
            self.next_chr()
        return self.words.get(s, s)

    def number(self):
        def next_digit(err):
            n = self.ch
            self.next_chr()
            if not self.ch or not self.ch.isdigit():
                raise ParseError(err)
            return n
        n = ''
        try:
            if self.ch == '-':
                n += next_digit(ERRORS['mfnumber_minus'])
            n += self.digit()
            if n == '0' and self.ch in ['x', 'X']:
                n += self.ch
                self.next_chr()
                n += self.hex()
            else:
                if self.ch and self.ch == '.':
                    n += next_digit(ERRORS['mfnumber_dec_point'])
                    n += self.digit()
                if self.ch and self.ch in ['e', 'E']:
                    n += self.ch
                    self.next_chr()
                    if not self.ch or self.ch not in ('+', '-'):
                        raise ParseError(ERRORS['mfnumber_sci'])
                    n += next_digit(ERRORS['mfnumber_sci'])
                    n += self.digit()
        except ParseError:
            t, e = sys.exc_info()[:2]
            print(e)
            return 0
        try:
            return int(n, 0)
        except:
            pass
        return float(n)

    def digit(self):
        n = ''
        while self.ch and self.ch.isdigit():
            n += self.ch
            self.next_chr()
        return n

    def hex(self):
        n = ''
        while self.ch and (self.ch in 'ABCDEFabcdef' or self.ch.isdigit()):
            n += self.ch
            self.next_chr()
        return n


slpp = SLPP()

__all__ = ['slpp']
