---
title: Arithmetic
description: Making calculations with dates, times and durations.
order: 30
---
You can add durations to dates, subtract durations from dates and subtract dates from dates.
You can divide and multiply durations. Parentheses work.

```
# Add 2 days to a date.
June 17th 2017, 12:00:03.000 + 2d

# Subtract 3 hours and 25 minutes from a date.
2017-08-15T12:28:34.395-05:00 - 3h 25m

# Subtract one date from another.
2017-06-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000

# Twice the difference between two dates added 
# to a third date.
((2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) * 2) + 1499212382
```    

