---
title: Duration conversion
description: Converting durations into different units, for example hours.
order: 70
---
You can display a duration broken down into days, hours, minutes, seconds or milliseconds. If the duration can't be completely
expressed in the chosen unit then the remaining milliseconds are also formatted.

````
# How many seconds in 14 hours.
14h . s

# How many minutes between two dates.
(2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) . m

# As days?
(2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) . d
````    
