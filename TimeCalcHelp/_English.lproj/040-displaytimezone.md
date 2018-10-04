---
title: Display timezone
description: Display dates and times in a different timezone.
order: 40
---
By default dates are displayed in the current TimeZone. To use a different TimeZone you add
`@ tz`  where `tz` is an abbrevation or name, for example `@ UTC`. You can also use a variable.

```
# Convert to central daylight time.
2017-06-17 12:00:03.340 -07:00 @ CDT

# Use the timezone name.
2017-06-17 12:00:03.340 -07:00 @ America/Chicago

now @ America/North_Dakota/New_Salem

now @ UTC

let x = `America/Chicago`
now @ x
```
