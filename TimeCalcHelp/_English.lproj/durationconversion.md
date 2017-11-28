---
title: Duration conversion
description: Converting durations into different units, for example hours.
order: 70
---
You can convert a duration into day, hours, minutes, seconds or milliseconds. If the duration can't be completely
expressed in the chosen unit then the remaining milliseconds are also shown.

    # How many seconds in 14 hours -> 50400s
    14h . s
    # How many minutes between two dates -> 2851m 29000ms
    (2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) . m
    # As days? -> 1d 84689000ms
    (2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) . d
    # Remaining milliseconds can be parsed -> 29s
    29000ms
    # And -> 23h 31m 29s
    84689000ms
