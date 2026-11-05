# Linux-Scripts

> Repository maintained by Muhammed Salman CC

## Overview

This repository is part of my M.Sc. Electronics work at CUSAT.

It includes a comprehensive **Linux Commands Library** for students, developers, DevOps engineers, and system administrators.

## Linux Commands Library

Full 20-section documentation for essential Linux commands:

**[docs/linux-commands/](docs/linux-commands/README.md)**

| Command | Category | Documentation |
|---------|----------|---------------|
| [`ls`](docs/linux-commands/ls.md) | File & directory | List directory contents |
| [`cp`](docs/linux-commands/cp.md) | File & directory | Copy files and directories |
| [`mv`](docs/linux-commands/mv.md) | File & directory | Move / rename files |
| [`find`](docs/linux-commands/find.md) | File & directory | Search the filesystem |
| [`grep`](docs/linux-commands/grep.md) | Text processing | Search text patterns |
| [`sed`](docs/linux-commands/sed.md) | Text processing | Stream editor |
| [`awk`](docs/linux-commands/awk.md) | Text processing | Field-oriented processing |
| [`tar`](docs/linux-commands/tar.md) | Archiving | Create / extract archives |
| [`rsync`](docs/linux-commands/rsync.md) | Transfer & backup | Incremental sync |
| [`ssh`](docs/linux-commands/ssh.md) | Remote access | Secure shell |
| [`systemctl`](docs/linux-commands/systemctl.md) | Systemd | Service management |
| [`journalctl`](docs/linux-commands/journalctl.md) | Systemd | Journal log queries |

Each document covers syntax, purpose, internals, options, examples (beginner → real-world), comparisons, advantages/disadvantages, exit codes, errors, best practices, interview questions, exam notes (RHCSA/RHCE/LPIC/Linux+), man page summary, shell compatibility, use cases, tips, and a concise summary.

A reusable blank structure is available at [`docs/linux-commands/TEMPLATE.md`](docs/linux-commands/TEMPLATE.md).

## Utility scripts

Executable Bash utilities in [`scripts/`](scripts/), each with a
`--help` header and functional tests in
[`tests/run_tests.sh`](tests/run_tests.sh):

| Script | What it does |
| ------ | ------------ |
| [`sys_health.sh`](scripts/sys_health.sh) | Load/memory/disk summary with OK/WARN/CRIT verdicts and a non-zero exit on CRIT |
| [`backup_rotate.sh`](scripts/backup_rotate.sh) | Timestamped tar backup with count-based rotation and a dry-run mode |

Run the tests with:

```sh
tests/run_tests.sh
```

## Status

🚧 Active Development

## License

MIT
