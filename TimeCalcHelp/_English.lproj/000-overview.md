---
title: Overview
description: Overview of functionality and the window layout
order: -.INF
---

TimeCalc is a scratch pad for converting between different date formats and making calculations with dates
and durations. For example how far apart are the date from a Kibana log
message and the timesamp of a Cassandra column?

`September 6th 2017, 19:04:55.000 - 1504742693764001` it's `1s 235ms`

Or, what's two minutes and 13 seconds after a time in seconds since epoc?

`1499212382 + 2m 13s` it's `2017-07-04 18:55:15 -05:00`

Expressions are entered in the left pane and their values are displayed in the right pane. One
expression per line. A line that starts with `#` is a comment. Datetimes, durations and arithmetic
operations on them are supported. Whenever the text on the left is modified the results on the right are
recalculated.

![Main Screen](TimeCalcOverview.png)

Here's the text from the screen shot if you want to paste it in to try it out.

```
# Enter text on left, results on right.
September 29th 2019, 14:16:06.412 
# Display in a different timezone.
September 29th 2019, 14:16:06.412 @ UTC
# Date as s (or ms) since epoc
2019-12-02T21:20:23 as s
# Time in ms (or s) is also understood.
1569784566412
# Different output formats.
1569784566412 as "MM-dd"
2019-12-02T21:20:23  as "yy/MM/dd"
# Difference between dates (a duration).
29/Sep/2019:19:20:08 +0000 - 1569784566412
# Adding (or subtracting) offsets
2019/12/03T10:10:10 + 1d 2h 3m
# Division of a duration.
(1569784566412 - 2019-12-02T21:20:23) / 10
```
