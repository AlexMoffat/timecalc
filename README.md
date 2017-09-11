# TimeCalc

A simple calculator for working with datetime values in different formats.

Type expressions on the left, see the results on the right.

## Syntax

One expression per line.

Comments start with #.

Datetimes, durations and arithmetic operations on them are supported.

Some examples. First of all, parsing dates.  All of the formats below are understood

    # Standard iso format.
    2017-06-17T17:00:03-05:00
    # Also with UTC
    2017-06-17T19:00:03Z
    # And millisecond precision
    2017-08-15T12:28:34.395-05:00
    # Very similar to above but with spaces
    2017-08-15 17:28:34 +0000
    # And again with milliseconds
    2017-08-15 17:28:34.456 +0000
    # A format that Kibana likes with the name of the month
    June 17th 2017, 12:00:03.000
    # Bamboo's date format (assumed current timezone)
    20-Jul-2017 22:02:26
    # Milliseconds since epoch
    1499212382123
    # And seconds since epoch
    1499212382

Durations are written as a combination of days, hours, minutes, seconds and milliseconds.

    # Two days.
    2d
    # Three days and 1 hour.
    3d 1h
    # Intermediate units can be omitted. One day and 3 minutes.
    1d 3m
    # All of the possible units.
    2d 1h 15m 23s 245ms

You can add durations to dates, subtract durations from dates and subtract dates from dates.
You can divide and multiply durations. Parentheses work.

    # Add 2 days to date
    June 17th 2017, 12:00:03.000 + 2d
    # Subtract 3 hours and 25 minutes from a date
    2017-08-15T12:28:34.395-05:00 - 3h 25m
    # Subtract one date from another
    2017-06-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000
    # Twice the difference between two dates added to a third date
    ((2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) * 2) + 1499212382
    
Results can be shown in different timezone using abbreviations or names.

    # Convert to central daylight time.
    2017-06-17 12:00:03.340 -07:00 @ "CDT"
    # Use the timezone name
    2017-06-17 12:00:03.340 -07:00 @ "America/Chicago"

