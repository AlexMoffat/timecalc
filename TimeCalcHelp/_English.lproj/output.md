---
title: Output formats
description: Changing the format for dates, times and datetimes.
order: 90
---
The `fmt` variable controls the output format for dates.

    # Format to show just the date -> yyyy-MM-dd
    let fmt = "yyyy-MM-dd"
    # What does it show? -> 2017-08-15
    2017-08-15 17:28:34 +0000
    # Go back to the default formats -> <nothing>
    let fmt = ""
    # What does it show? -> 2017-08-15 12:28:34 -05:00
    2017-08-15 17:28:34 +0000
    # or use singe quotes. Single and double quotes work the same way.
    let fmt = ''
