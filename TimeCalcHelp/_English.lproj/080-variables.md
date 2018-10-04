---
title: Variables
description: Using variables to store and retrieve values.
order: 80
---
Variables can be defined. The right hand side after the = can be any expression.

```
# Define x.
let x = 2017-09-03
    
# And use it.
x . day
```

There are seven reserved variables whose values you can't change `now`, `day`, `d`, `h`, `m`, `s`, and `ms`.
There are also two special variables `fmt` and `tz` whose value you can modify but which have special effects. 
`now` is shown below, see [`fmt`](output.html) and [`tz`](timezone.html) for information on those variables. 

```
# now shows the current date and time.
now
    
# It can be used in expressions like any variable.
now + 3h 2m
```
