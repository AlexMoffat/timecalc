---
title: Output formats
description: Changing the display format for dates, times and datetimes.
order: 90
---
The `fmt` variable controls the output format for dates. [Date format patterns](http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns) describes
what can go into a valid pattern. If `fmt` isn't set the default pattern is `yyyy-MM-dd HH:mm:ss ZZZZZ` with fractional seconds if needed.

```
# Format to show just the date.
let fmt = "yyyy-MM-dd"

# What does it show?
2017-08-15 17:28:34 +0000

# Go back to the default formats.
let fmt = ""

# What does it show?
2017-08-15 17:28:34 +0000

# Or use singe quotes. Single and double quotes work the same way.
let fmt = ''
```
