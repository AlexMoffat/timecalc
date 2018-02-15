---
title: Elapsed since epoc
description: Dates and times as seconds or milliseconds since the epoch.
order: 50
---
You can convert a date to the seconds/milliseconds since the epoc by using `. s` or `. ms` after the date.
Dates converted to seconds/milliseconds don't have a following unit because they represent dates,
with a unit they would be interpreted as durations.

```
# Seconds since epoc.
(2017-06-17T19:00:03 + 33m) . s

# Milliseconds since epoc.
2017-08-15T12:28:34.395-05:00 . ms
```
