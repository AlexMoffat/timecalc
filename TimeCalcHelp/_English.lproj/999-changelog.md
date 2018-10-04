---
title: Changelog
description: Changes from one version to another
order: 999
---

## 1.4 to 1.5

The value on the right hand side of a change timezone operator ( `@` ) no longer has to be a string, for example
`@ "UTC"` or `@ "America/Chicago"`. You can use a bare value, for example `@ UTC` or `@ America/Chicago`, instead,
or a variable, for example `@ x` where you've previously given `x` a value, for example, `let x = "UTC"`. The value of
a variable is used in preference to its name, so if you give `UTC` a value, for example, `let UTC = "America/Chicago"` 
the value `America/Chicago` will be used when you say `@ UTC`, which will be confusing.
