---
title: Parsed Date Formats
description: Supported date, time, and datetime formats.
order: 10
---
Many date formats are supported. Some examples are shown below.  You can copy and paste the examples into the expression window 
to see the results. See the Default TimeZone section below for information on how the timezone is chosen if none is provided in the input
format. In most cases current timezone is used. Exceptions noted below.

```
# Standard iso format
2017-06-17T17:00:03 -05:00

# Also with UTC 
2017-06-17T19:00:03Z

# And millisecond precision
2017-08-15T12:28:34.395-05:00

# Very similar to above but with spaces
2017-08-15 17:28:34 +0000

# And again with milliseconds 
2017-08-15 17:28:34.456 +0000

# A format with the name of the month
June 17th 2017, 12:00:03.000

# Bamboo's date format with UTC 
20-Jul-2017 22:02:26 Z

# Bamboo's date format 
# (assumes UTC timezone, not current)
20-Jul-2017 22:02:26

# Format from Sentry
Sep 29, 2017 2:00:23 PM UTC

# Milliseconds since epoch. 13 digits
1499212382123

# And seconds since epoch. 10 digit
1499212382

# Very similar format for json serialized java 
# Interval seconds since epoch. 10 digit with 
# fraction
1502713067.720000000

# Microseconds since epoc is also supported. 16 digits. 
# This is the format of a Cassandra column timestamp.
1504742693764001

# Just a date is treated as midnight current timezone 
2017-09-03
```
