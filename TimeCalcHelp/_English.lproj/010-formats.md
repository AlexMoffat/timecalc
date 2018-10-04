---
title: Supported Date Formats
description: Supported date, time, and datetime formats.
order: 10
---
Supported date formats are listed below with examples.  You can copy and paste the examples into the expression window 
to see the results. See the [TimeZone](timezone.html) section for information on how the timezone is chosen if none is provided 
in the input format. In most cases current timezone is used. Exceptions noted below.

```
# ISO format. TimeZone is optional.
2017-06-17T17:00:03-05:00 
2017-06-17T17:00:03+00:00
2017-06-17T19:00:03Z
2017-06-17T17:00:03

# ISO like with spaces.
2017-06-17 17:00:03 -05:00 
2017-08-15 17:28:34 +0000
2017-08-15 17:28:34 Z
2017-08-15 17:28:34

# All ISO format and ISO like are also recognized
# with milliseconds with either a period or comma.
# For example
2017-08-15T12:28:34.395-05:00
2018-02-07 20:05:36,501

# A format that [Kibana](https://www.elastic.co/products/kibana) uses with the name of the month
June 17th 2017, 12:00:03.000

# [Bamboo](https://www.atlassian.com/software/bamboo)'s date format with UTC and assuming UTC.
20-Jul-2017 22:02:26 Z
20-Jul-2017 22:02:26

# Bamboo's "completed" date format. Assumes UTC.
13 Feb 2018, 5:14:39 PM

# [Sentry](https://sentry.io) date formats.
Sep 29, 2017 2:00:23 PM UTC
Feb. 5, 2018, 7:19:18 p.m. UTC

# [Finatra](https://twitter.github.io/finatra/) access logging filter.
14/Feb/2018:14:39:14 +0000

# [Jira](https://www.atlassian.com/software/jira) date
06/Feb/18 8:38 AM

# Twitter API format
Tue Sep 19 15:04:28 +0000 2017

# Cookie expiry date as it appeared in some logging messages
Fri, 14 Feb 2020 14:39:13 UTC
# Similar but with dashes
Thu, 31-Jan-2019 23:57:29 GMT

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
