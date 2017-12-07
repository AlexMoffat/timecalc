---
title: Parsed Formats
description: Supported date, time, datetime and duration formats.
order: 10
---

    # Standard iso format -> 2017-06-17 17:00:03 -05:00
    2017-06-17T17:00:03-05:00
    # Also with UTC -> 2017-06-17 14:00:03 -05:00
    2017-06-17T19:00:03Z
    # And millisecond precision -> 2017-08-15 12:28:34.395000 -05:00
    2017-08-15T12:28:34.395-05:00
    # Very similar to above but with spaces -> 2017-08-15 12:28:34 -05:00
    2017-08-15 17:28:34 +0000
    # And again with milliseconds -> 2017-08-15 12:28:34.456 -05:00
    2017-08-15 17:28:34.456 +0000
    # A format that Kibana likes with the name of the month -> 2017-06-17 12:00:03 -05:00
    June 17th 2017, 12:00:03.000
    # Bamboo's date format with UTC (Bamboo outputs without Z but it's in UTC) -> 2017-07-20 17:02:26 -05:00
    20-Jul-2017 22:02:26 Z
    # Bamboo's date format (assumed current timezone) -> 2017-07-20 22:02:26 -05:00
    20-Jul-2017 22:02:26
    # Format from Sentry -> 2017-09-29 09:00:23 -05:00
    Sep 29, 2017 2:00:23 PM UTC
    # Milliseconds since epoch. 13 digits  -> 2017-07-04 18:53:02.123000 -05:00
    1499212382123
    # And seconds since epoch. 10 digit -> 2017-07-04 18:53:02 -05:00
    1499212382
    # Very similar format for json serialized java Interval seconds since epoch. 10 digit with fraction -> 2017-08-14 07:17:47.720 -05:00
    1502713067.720000000
    # Microseconds since epoc is also supported. 16 digits. This is the format of a Cassandra command line timestamp.
    # Just a date is treated as midnight current timezone -> 2017-09-03 00:00:00 -05:00
    2017-09-03
