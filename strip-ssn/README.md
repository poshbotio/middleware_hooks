# strip-ssn

## Overview

When a command response is sent back to the chat network, this middleware will search for possible Social Security numbers (SSNs) and sanitize them.

## Configuration

> This middleware is intended to be used as a `PreResponse` hook.
> Hooks of this type are executed **AFTER** commands are executed but **BEFORE** responses are sent back to the chat network.

No additional configuration is needed.

## Intended Hook Type

- **PreResponse**

  This middleware is intended to be used as a `PreResponse` hook.
  Hooks of this type are executed **AFTER** commands are executed but **BEFORE** responses are sent back to the chat network.

## Expected Behavior

When a PoshBot command response is about to be sent, the response text is first inspected for potential Social Security numbers and if detected, the numbers are sanitized and replaced with `#`.

## Contributors

- [Brandon Olin](https://github.com/devblackops)
