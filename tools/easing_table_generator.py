#!/usr/bin/python
# ----------------------------------------------------------------------------
# Easing Table Generator - riq
#
# Some formulas were taken from: http://easings.net/
# Others were taken from: https://github.com/cocos2d/cocos2d-x/blob/cocos2d-x-3.8rc0/cocos/2d/CCTweenFunction.cpp
# The rest, by Ricardo Quesada
# ----------------------------------------------------------------------------
'''
Easing Table Generator
'''
from __future__ import division, unicode_literals, print_function
import sys
import os
import getopt
import math


__docformat__ = 'restructuredtext'


def cubic_bezier_at(t, a, b, c, d):
    return (
        ((1-t)**3) * a +
        3 * ((1-t)**2) * t * b +
        3 * (1-t) * (t**2) * c +
        (t**3) * d
        )


#
# Different formulas. Must start with 'fn_'
#
def fn_linear(time):
    return time


def fn_bezier(time, a, b, c, d):
    """recieves 4 control points. Usually 'a' is 0, and 'd' is 1"""
    return cubic_bezier_at(time, a, b, c, d)


def fn_sin(time):
    return math.sin(time * math.pi)


# Ease - Sine
def fn_easeInSine(time):
    # return -1 * math.cos(time * math.pi/2) + 1
    # cubic-bezier(0.47, 0, 0.745, 0.715)
    return cubic_bezier_at(time, 0, 0, 0.715, 1)


def fn_easeOutSine(time):
    # return math.sin(time * math.pi/2)
    # cubic-bezier(0.39, 0.575, 0.565, 1);
    return cubic_bezier_at(time, 0, 0.575, 1, 1)


def fn_easeInOutSine(time):
    # return -0.5 * (math.cos(math.pi * time) - 1)
    # cubic-bezier(0.445, 0.05, 0.55, 0.95);
    return cubic_bezier_at(time, 0, 0.05, 0.95, 1)


# Ease - Quad
def fn_easeInQuad(time):
    # return time * time
    # cubic-bezier(0.55, 0.085, 0.68, 0.53);
    return cubic_bezier_at(time, 0, 0.085, 0.53, 1)


def fn_easeOutQuad(time):
    # return -1 * time * (time - 2)
    # cubic-bezier(0.25, 0.46, 0.45, 0.94);
    return cubic_bezier_at(time, 0, 0.46, 0.94, 1)


def fn_easeInOutQuad(time):
    # time = time * 2
    # if time < 1:
    #     return 0.5 * time * time
    # time = time - 1
    # return -0.5 * (time * (time - 2) - 1)
    # cubic-bezier(0.455, 0.03, 0.515, 0.955);
    return cubic_bezier_at(time, 0, 0.03, 0.955, 1)


# Ease - Cubic
def fn_easeInCubic(time):
    # return time * time * time
    # cubic-bezier(0.55, 0.055, 0.675, 0.19);
    return cubic_bezier_at(time, 0, 0.055, 0.19, 1)


def fn_easeOutCubic(time):
    # time = time - 1
    # return (time * time * time + 1)
    # cubic-bezier(0.215, 0.61, 0.355, 1);
    return cubic_bezier_at(time, 0, 0.61, 1, 1)


def fn_easeInOutCubic(time):
    # time = time * 2
    # if time < 1:
    #     return 0.5 * time * time * time
    # time = time - 2
    # return 0.5 * (time * time * time + 2)
    # cubic-bezier(0.645, 0.045, 0.355, 1);
    return cubic_bezier_at(time, 0, 0.045, 1, 1)


# Ease - Quart
def fn_easeInQuart(time):
    return cubic_bezier_at(time, 0, 0.03, 0.22, 1)


def fn_easeOutQuart(time):
    return cubic_bezier_at(time, 0, 0.84, 1, 1)


def fn_easeInOutQuart(time):
    return cubic_bezier_at(time, 0, 0, 1, 1),


# Ease - Quint
def fn_easeInQuint(time):
    return cubic_bezier_at(time, 0, 0.05, 0.06, 1)


def fn_easeOutQuint(time):
    return cubic_bezier_at(time, 0, 1, 1, 1)


def fn_easeInOutQuint(time):
    return cubic_bezier_at(time, 0, 0, 1, 1)


# Ease - Expo
def fn_easeInExpo(time):
    return cubic_bezier_at(time, 0, 0.05, 0.035, 1)


def fn_easeOutExpo(time):
    return cubic_bezier_at(time, 0, 1, 1, 1)


def fn_easeInOutExpo(time):
    return cubic_bezier_at(time, 0, 0, 1, 1)


# Ease - Circ
def fn_easeInCirc(time):
    return cubic_bezier_at(time, 0, 0.04, 0.335, 1)


def fn_easeOutCirc(time):
    return cubic_bezier_at(time, 0, 0.82, 1, 1)


def fn_easeInOutCirc(time):
    return cubic_bezier_at(time, 0, 0.135, 0.86, 1)


# Ease - Back
def fn_easeInBack(time):
    return cubic_bezier_at(time, 0, -0.28, 0.045, 1)


def fn_easeOutBack(time):
    return cubic_bezier_at(time, 0, 0.885, 1.275, 1)


def fn_easeInOutBack(time):
    return cubic_bezier_at(time, 0, -0.55, 1.55, 1)


# Ease - Elastic
def fn_easeInElastic(time, period=0.3):
    """recieves 1 argument"""
    newT = 0
    if time == 0 or time == 1:
        newT = time
    else:
        s = period / 4
        time = time - 1
        newT = -math.pow(2, 10 * time) * math.sin((time - s) * math.pi * 2 / period)

    return newT


def fn_easeOutElastic(time, period=0.3):
    """recieves 1 argument"""
    newT = 0
    if time == 0 or time == 1:
        newT = time
    else:
        s = period / 4
        newT = math.pow(2, -10 * time) * math.sin((time - s) * math.pi * 2 / period) + 1

    return newT


def fn_easeInOutElastic(time, period=0.3):
    """recieves 1 argument"""
    newT = 0
    if time == 0 or time == 1:
        newT = time
    else:
        time = time * 2
        if not period:
            period = 0.3 * 1.5

        s = period / 4

        time = time - 1
        if time < 0:
            newT = -0.5 * math.pow(2, 10 * time) * math.sin((time - s) * math.pi * 2 / period)
        else:
            newT = math.pow(2, -10 * time) * math.sin((time - s) * math.pi * 2 / period) * 0.5 + 1

    return newT


# Ease - Bounce
def bounce_time_old(time, bounces):
    ret = 0
    if time < 1 / 2.75:
        ret = math.pow(2.75, 2) * time * time
    elif time < 2 / 2.75:
        time = time - 1.5 / 2.75
        ret = math.pow(2.75, 2) * time * time + 0.75
    elif time < 2.5 / 2.75:
        time = time - 2.25 / 2.75
        ret = math.pow(2.75, 2) * time * time + 0.9375
    else:
        time = time - 2.625 / 2.75
        ret = math.pow(2.75, 2) * time * time + 0.984375
    return ret


def bounce_time_new(time, bounces):
    bounces = int(bounces)
    ret = 1
    # magic = 2 + 2/2 + 2/4 + 2/8 + ...
    # magic -= 1 since the first "2" should be "2/2" since it is a half jump
    l = [2.0/pow(2, x) for x in range(bounces)]
    # first value is always 1, since it is 2/2
    l[0] = 1
    magic = sum(l)

    # first bounce, is half bounce
    if time < 1 / magic:
        ret = math.pow(magic, 2) * time * time
    else:
        # skip first bounce
        accum = l[0]
        for i in range(1, bounces):
            accum = accum + l[i]
            if time < (accum/magic):
                time = time - (accum-l[i]/2) / magic
                s = math.pow(l[i]/2, 2)
                ret = math.pow(magic, 2) * time * time + (1-s)
                break
    return ret


# bounce_time_new supports multiple bounces
bounce_time = bounce_time_new


def fn_easeInBounce(time, bounces=4):
    return 1 - bounce_time(1 - time, bounces)


def fn_easeOutBounce(time, bounces=4):
    return bounce_time(time, bounces)


def fn_easeInOutBounce(time, bounces=4):
    newT = 0
    if time < 0.5:
        time = time * 2
        newT = (1 - bounce_time(1 - time, bounces)) * 0.5
    else:
        newT = bounce_time(time * 2 - 1, bounces) * 0.5 + 0.5

    return newT


#
def parse_args(formula):
    # valid formula formats:
    #  - 'easeInSine'
    #  - 'easeInOutSine:'
    #  - 'bezier:0,0.1,0.93,1'
    args_float = None
    l = formula.split(':')
    formula_name = l[0]
    if len(l) == 2:
        args = l[1]
        # it might have multiple args separated by ','
        args = args.split(',')
        args_float = [float(x) for x in args]
    formula_name = 'fn_' + formula_name
    if not args_float:
        args_float = []
    return formula_name, args_float


def print_list(l, absolute, last_value):
    last = last_value
    for i, item in enumerate(l):
        if not absolute:
            new_item = item - last
            last = item
            item = new_item % 256
        if i % 8 == 0:
            sys.stdout.write('\n.byte %3d' % item)
        else:
            sys.stdout.write(',%3d' % item)
    sys.stdout.write('\n')


def convert_value(val, maxvalue):
    # FIXME: for 16-bit numbers, this should be 65536
    return int(round(val * float(maxvalue))) % 256


def run(formula, steps, maxvalue, reverse, absolute):
    formula_name, args = parse_args(formula)
    try:
        fn = getattr(sys.modules[__name__], formula_name)
    except AttributeError:
        raise Exception("Invalid formula name: %s" % formula)
    l = []

    for i in range(steps):
        # does not include time=0, but includes time=1
        time = (i+1) / steps
        ret = fn(time, *args)
        l.append(convert_value(ret, maxvalue))

    # print 8 elements per line
    sys.stdout.write('; autogenerated table: %s -s%s -m%s -a%s %s%s ' % (os.path.basename(sys.argv[0]), steps, maxvalue, absolute, '-r ' if reverse else '', formula))
    print_list(l, absolute, 0)

    # reverse ?
    if reverse:
        # reverse list
        l.reverse()
        # remove first element, when time == 1
        last_value = l[0]
        del l[0]
        # append new element, when time == 0
        ret = fn(0, *args)
        l.append(convert_value(ret, maxvalue))

        sys.stdout.write('; reversed')
        print_list(l, absolute, last_value)


def list_formulas():
    l = dir(sys.modules[__name__])
    formulas = [x[3:] for x in l if x.startswith('fn_')]
    print("Valid formulas:")
    for f in formulas:
        print("\t%s" % f)


def help():
    print("%s v0.1 - An utility to create easing tables. Useful for c64 and other 8-bit computers" % os.path.basename(sys.argv[0]))
    print("\nUsage: %s [options] formula_name" % os.path.basename(sys.argv[0]))
    print("\t-s tablesize\t\t\ttable size. Default=256")
    print("\t-m maxvalue\t\t\tmax value for the table. Default=128")
    print("\t-r\t\t\t\twill also generate the reversed table. Default: no reverse table")
    print("\t-a true|false\t\t\tabsolute or relative output. Default: true")
    print("\t-l\t\t\t\tlist available formulas")
    print("\tformula_name[:args]\t\toptinal arguments can be passed by appending ':'")
    print("\nExamples:")
    print("\t%s -s256 easeInSine" % os.path.basename(sys.argv[0]))
    print("\t%s -s128 -m40 -r -atrue easeInOutCubic" % os.path.basename(sys.argv[0]))
    print("\t%s -m40 -r  -afalse bezier:0,0.2,0.8,1" % os.path.basename(sys.argv[0]))
    print("\t%s easeInElastic:0.3" % os.path.basename(sys.argv[0]))
    print("\t%s -l" % os.path.basename(sys.argv[0]))
    sys.exit(-1)


if __name__ == "__main__":
    if len(sys.argv) == 1:
        help()

    formula = None
    steps = 256
    maxvalue = 128
    reverse = False
    absolute = True

    argv = sys.argv[1:]
    try:
        opts, args = getopt.getopt(argv, "lrs:m:a:", ["listformulas", "reverse", "tablesize=", "maxvalue=", "absolute="])
        for opt, arg in opts:
            if opt in ("-l", "--listformulas"):
                list_formulas()
                exit(0)
            elif opt in ("-s", "--tablesize"):
                steps = int(arg)
            elif opt in ("-m", "--maxvalue"):
                maxvalue = arg
            elif opt in ("-r", "--reverse"):
                reverse = True
            elif opt in ("-a", "--absolute"):
                absolute = (arg.lower()[0] == 't' or arg.lower()[0] == 'y' or arg == '1')
        if not len(args) == 1:
            help()
        else:
            formula = args[0]
    except getopt.GetoptError as e:
        print(e)

    run(formula, steps, maxvalue, reverse, absolute)
