---
title: Parsing timezone
description: Changing the default timezone for parsing.
order: 95
---
The `tz` variable controls the TimeZone used when parsing date formats that don't have a specific TimeZone. For instance
`2017-06-17T17:00:03-05:00`  specifies a TimeZone while `2017-06-17T17:00:03` does not. The default is the user's current TimeZone
but setting `tz` changes this.

```
# No timezone in the input so the 
# current TimeZone is used.
2017-06-17T17:00:03
    
# Set the default to UTC
let tz = 'UTC'

# Parse the same value but see
# a different value in the current timezone.
2017-06-17T17:00:03

# Reset to current timezone by setting tz
# to an empty string.
let tz = ''
```    
