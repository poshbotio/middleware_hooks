# adauth

## Overview

This middleware hook takes the user name property of the incoming message and validates if the user is a member of the specified Active Directory group.
If the user is a member, the command is allowed. If not, the message is dropped.

## Configuration

Enter the Active Directory group name to validate the user is a member of.

```powershell
$adGroup = 'botusers'
```

## Intended Hook Type

- **PreExecute**

  This middleware is intended to be used as a `PreExecute` hook.
  Hooks of this type are executed **AFTER** messages are resolved to commands but **BEFORE** the command is executed.

## Expected Behavior

When a PoshBot command is received, the user is checked to see if they are a member of the specified group.
If they are, the command is allowed to run, if not, the message is dropped.

## Contributors

- [Brandon Olin](https://github.com/devblackops)
