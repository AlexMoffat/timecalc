---
title: Durations
description: Describing elapsed times.
order: 20
---
Durations are written as a combination of days, hours, minutes, seconds and milliseconds. Two formats 
are supported for parsing. All durations are output in the TimeCalc format.

## TimeCalc

A sequence of separate pieces separated by spaces. Each piece of a duration must have a unit. The suffixes for 
units are `d` (days),` h` (hours), `m` (minutes), `s` (seconds) and `ms` (milliseconds). This is the format for duration output.

```
# Two days.
2d

# Three days and 1 hour.
3d 1h

# Intermediate units can be omitted. 
# One day and 3 minutes
1d 3m

# All of the possible units.
2d 1h 15m 23s 245ms
```
## Java Duration / ISO 8601

A single string starting with a `P` and then optional days, then `T` and time component. Letters may be upper or lower case.

```
# Two days.
P2D

# Three days and 1 hour.
P3DT1H

# One day and 3 minutes.
P1DT3M

# 30 minutes and 10 seconds. T is required even if there are no days.
PT30M10S

# All possible units.
p2d1h15m23.245s
```
