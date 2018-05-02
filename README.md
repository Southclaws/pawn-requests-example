# pawn-requests-example

[![sampctl](https://shields.southcla.ws/badge/sampctl-pawn--requests--example-2f2f2f.svg?style=for-the-badge)](https://github.com/Southclaws/pawn-requests-example)

This package demonstrates simple usage of the
[pawn-requests](https://github.com/Southclaws/pawn-requests) plugin.

Inside `test.pwn` is a simple gamemode that uses
[jsonstore.io](https://jsonstore.io) to save and load player data as JSON.

See source code for comments explaining the process.

## Usage

Once you have the package cloned locally, install the dependencies:

```bash
sampctl package ensure
```

You can use your own endpoint by visiting [jsonstore.io](https://jsonstore.io)
and copying the URL here:

![https://i.imgur.com/j9Pe8S6.png](https://i.imgur.com/j9Pe8S6.png)

Into the `endpoint` value in `settings.ini`.
