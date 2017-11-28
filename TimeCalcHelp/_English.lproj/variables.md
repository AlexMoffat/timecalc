---
title: Variables
description: Using variables to store and retrieve values.
order: 80
---
Variables can be defined. The right hand side after the = can be any expression.

    # define x -> 2017-09-03 00:00:00 -05:00
    let x = 2017-09-03
    # use it -> Sunday
    x . day

There are seven reserved variables whose values you can't change `now`, `day`, `d`, `h`, `m`, `s`, and `ms`.
There's also one special variable `fmt` whose value you can modify but which has special effects.

    # now shows the current date and time. Maybe -> 2017-11-12 19:21:52.185000 -06:00
    now
    # It can be used in expressions like any variable. Maybe -> 2017-11-12 22:34:57.161000 -06:00
    now + 3h 2m
