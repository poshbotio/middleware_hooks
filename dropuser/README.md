# dropuser

## Overview

There may be times where you need to drop ALL PoshBot commands from certain users before they are executed.
This middleware hook does just that.

## Configuration

> This middleware is intended to be used as a `PreReceive` hook.
> Hooks of this type are executed **BEFORE** chat messages are resolved to commands.

Enter the list of usernames you wish to drop.

```powershell
$blacklistedUsers = @('sally', 'bob')
```

## Intended Hook Type

- **PreReceive**

  This middleware is intended to be used as a `PreReceive` hook.
  Hooks of this type are executed **BEFORE** chat messages are resolved to commands.

## Expected Behavior

When a PoshBot command is received from any of the listed users, their messages will be dropped and PoshBot **will not** execute them.

## Contributors

- [Brandon Olin](https://github.com/devblackops)
