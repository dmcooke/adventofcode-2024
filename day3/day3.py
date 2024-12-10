#!/usr/bin/env python3

import re
import time

def readinput():
    with open('input.txt', 'r', encoding='utf-8') as fo:
        return fo.read()

PATTERN1 = re.compile(r'mul\(([1-9][0-9]{0,2}),([1-9][0-9]{0,2})\)')

def part1(instr):
    total = 0
    for m in PATTERN1.finditer(instr):
        total += int(m.group(1)) * int(m.group(2))
    return total

PATTERN2 = re.compile(r"""
(do\(\))
|(don't\(\))
|(?:""" + PATTERN1.pattern + ")", re.X)

def part2(instr):
    total = 0
    enabled = True
    for m in PATTERN2.finditer(instr):
        if m.group(1):
            enabled = True
        elif m.group(2):
            enabled = False
        elif enabled:
            total += int(m.group(3)) * int(m.group(4))
    return total

def part2_bychar(instr):
    length = len(instr)
    i = 0
    total = 0
    enabled = True
    while i < length:
        c = instr[i]
        i += 1
        if c == "d":
            if i >= length:
                break
            c = instr[i]
            if c != "o":
                continue
            i += 1
            c = instr[i]
            if c == "n":
                i += 1
                c = instr[i:i+4]
                if c != "'t()":
                    continue
                i += 4
                enabled = False
            elif c == "(":
                i += 1
                if i >= length:
                    break
                c = instr[i]
                if c != ")":
                    continue
                i += 1
                enabled = True
            else:
                continue
        elif c == "m":
            if not enabled:
                continue
            c = instr[i:i+3]
            if c != "ul(":
                continue
            i += 3
            if i >= length:
                break
            c = instr[i]
            oc = ord(c)
            if oc < 48 or 57 < oc:
                continue
            i += 1
            x = oc - 48
            if i >= length:
                break
            c = instr[i]
            i += 1
            oc = ord(c)
            if 48 <= oc <= 57:
                x = 10*x + (oc - 48)
                if i >= length:
                    break
                c = instr[i]
                i += 1
                oc = ord(c)
                if 48 <= oc <= 57:
                    x = 10*x + (oc - 48)
                    if i >= length:
                        break
                    c = instr[i]
                    i += 1
            if c != ",":
                i -= 1
                continue
            if i >= length:
                break
            c = instr[i]
            oc = ord(c)
            if oc < 48 or 57 < oc:
                continue
            i += 1
            y = oc - 48
            if i >= length:
                break
            c = instr[i]
            i += 1
            oc = ord(c)
            if 48 <= oc <= 57:
                y = 10*y + (oc - 48)
                if i >= length:
                    break
                c = instr[i]
                i += 1
                oc = ord(c)
                if 48 <= oc <= 57:
                    y = 10*y + (oc - 48)
                    if i >= length:
                        break
                    c = instr[i]
                    i += 1
            if c != ")":
                i -= 1
                continue
            total += x * y
    return total


def part2_iter(instr):
    total = 0
    enabled = True
    it = iter(instr)
    cback = None
    c = "X"

    def match_chars(s):
        nonlocal cback
        for c0 in s:
            c = next(it, "")
            if c != c0:
                if c in ("d", "m"):
                    cback = c
                return False
        return True

    def match_int(termchar):
        nonlocal cback
        c = next(it, "")
        if not c.isascii() or not c.isdigit():
            if c in ("d", "m"):
                cback = c
            return None
        x = int(c)
        c = next(it, "")
        if c.isascii() and c.isdigit():
            x = 10*x + int(c)
            c = next(it, "")
            if c.isascii() and c.isdigit():
                x = 10*x + int(c)
                c = next(it, "")
        if c != termchar:
            if c in ("d", "m"):
                cback = c
            return None
        return x

    while True:
        if cback is not None:
            c, cback = cback, None
        else:
            c = next(it, "")
        match c:
            case "":
                break
            case "d":
                if not match_chars("o"):
                    continue
                c = next(it, "")
                match c:
                    case "n":
                        if not match_chars("'t()"):
                            continue
                        enabled = False
                    case "(":
                        if not match_chars(")"):
                            continue
                        enabled = True
                    case _:
                        if c not in ("d", "m"):
                            cback = c
                        continue
            case "m":
                if not enabled:
                    continue
                if not match_chars("ul("):
                    continue
                x = match_int(",")
                if x is None:
                    continue
                y = match_int(")")
                if y is None:
                    continue
                total += x * y
    return total

def part2_find(instr):
    length = len(instr)
    i = 0
    total = 0
    next_mul = instr.find("mul(")
    if next_mul == -1:
        return 0
    next_do = instr.find('do()')
    if next_do == -1:
        next_do = length
    next_dont = instr.find("don't()")
    if next_dont == -1:
        next_dont = length
    while i < length:
        if next_mul < next_dont:
            i = next_mul + 4
            next_mul = instr.find("mul(", i + 4)
            # minimum number of extra characters after mul(
            if i + 4 >= length:
                break
            j = instr.find(",", i, i + 4)
            if j == -1:
                continue
            xs = instr[i:j]
            if not xs.isascii() or not xs.isdigit():
                continue
            x = int(xs)
            i = j + 1
            j = instr.find(")", i, i + 4)
            if j == -1:
                continue
            ys = instr[i:j]
            if not ys.isascii() or not ys.isdigit():
                continue
            y = int(ys)
            total += x * y
            if next_mul == -1:
                break
        else:
            # No mul() before the next don't()
            # Skip ahead to don't()
            i = next_dont + len("don't()")
            # Update next_do if our last found was before the don't()
            if next_do < i:
                next_do = instr.find("do()", i)
                if next_do == -1:
                    # No do(), so no more updating total
                    break
            # Now, skip ahead to do(), b/c in don't() .. do() we do nothing
            i = next_do + len("do()")
            # Update next_dont to be after the do()
            next_dont = instr.find("don't()", i)
            if next_dont == -1:
                next_dont = length
            # Also update next_mul, as it needs to be after do() also
            if next_mul < i:
                next_mul = instr.find("mul(", i)
                if next_mul == -1:
                    break
    return total

clock = time.monotonic_ns

def measure(msg, func, *args):
    times = []
    for _ in range(3):
        bt = clock()
        total = func(*args)
        et = clock()
        times.append((et - bt) / 1000)
    print(f"{msg} {total}  (in {times} μs)")

def main():
    instr = readinput()
    measure('Part 1: Total sum is', part1, instr)
    measure('Part 2: Total sum is', part2, instr)
    measure('Part 2 (by char): Total sum is', part2_bychar, instr)
    measure('Part 2 (iter): Total sum is', part2_iter, instr)
    measure('Part 2 (find): Total sum is', part2_find, instr)

if __name__ == '__main__':
    main()
