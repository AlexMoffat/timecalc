---
title: Changelog
description: Changes from one version to another
order: 999
---

## 1.5 to 1.6

Replaced the `.` operator with `as` and added support for using `as` to provide custom output formats for dates as an 
alternative to setting the `fmt` variable. 
Modified the Makefile used as part of the build process for the help resources to assume homebrew installed ruby version
2.6.n with locally installed jekyll if no rvm configuration found.

## 1.4 to 1.5

The value on the right hand side of a change timezone operator ( `@` ) no longer has to be a string, for example
`@ "UTC"` or `@ "America/Chicago"`. You can use a bare value, for example `@ UTC` or `@ America/Chicago`, instead,
or a variable, for example `@ x` where you've previously given `x` a value, for example, `let x = "UTC"`. The value of
a variable is used in preference to its name, so if you give `UTC` a value, for example, `let UTC = "America/Chicago"` 
the value `America/Chicago` will be used when you say `@ UTC`, which will be confusing.
