---
title: Duration conversion
description: Converting durations into different units, for example hours.
order: 70
---
You can display a duration broken down into days, hours, minutes, seconds or milliseconds. If the duration can't be completely
expressed in the chosen unit then the remaining milliseconds are also formatted. The valid units are
 
 - `d` days
 - `h` hours
 - `m` minutes
 - `s` seconds
 - `ms` milliseconds

````
# How many seconds in 14 hours?
14h as s

# How many minutes between two dates?
(2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) as m

# As days?
(2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) as d
````    
