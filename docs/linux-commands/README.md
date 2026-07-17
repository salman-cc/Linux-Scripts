# Linux Commands Library

> Comprehensive reference documentation for students, developers, DevOps engineers, and system administrators.

**Repository:** [ccsalman545/Linux-Scripts](https://github.com/ccsalman545/Linux-Scripts)  
**Maintainer:** Muhammed Salman CC  
**Audience:** Beginners → Advanced | RHCSA · RHCE · LPIC · Linux+ · DevOps interviews

---

## How to Use This Library

Each command page follows a fixed **20-section structure**:

| # | Section | What you get |
|---|---------|--------------|
| 1 | Command Name | Syntax + short description |
| 2 | Purpose | Why it exists and when to use it |
| 3 | How it Works | Internals and key concepts |
| 4 | Common Options | Option table with examples |
| 5 | Practical Examples | Beginner → real-world admin |
| 6 | Similar Commands | Comparison table |
| 7 | Advantages | Performance, automation, security |
| 8 | Disadvantages | Limits, risks, mistakes |
| 9 | Exit Status | Common exit codes |
| 10 | Common Errors | Errors, causes, fixes |
| 11 | Best Practices | Production-safe usage |
| 12 | Related Commands | Commands used together |
| 13 | Cheat Sheet | Quick reference |
| 14 | Interview Questions | Beginner / intermediate / advanced |
| 15 | Exam Notes | RHCSA, RHCE, LPIC, Linux+ |
| 16 | Man Page Summary | Manual sections in plain language |
| 17 | Shell Compatibility | Bash, Zsh, Fish, Dash, BusyBox |
| 18 | Real-World Use Cases | DevOps, cloud, security, etc. |
| 19 | Tips & Tricks | Expert shortcuts and aliases |
| 20 | Summary | Concise wrap-up |

---

## Command Index

### File & Directory Operations

| Command | Description | Doc |
|---------|-------------|-----|
| [`ls`](ls.md) | List directory contents | [Open](ls.md) |
| [`cp`](cp.md) | Copy files and directories | [Open](cp.md) |
| [`mv`](mv.md) | Move / rename files and directories | [Open](mv.md) |
| [`find`](find.md) | Search for files by name, type, time, size | [Open](find.md) |

### Text Processing

| Command | Description | Doc |
|---------|-------------|-----|
| [`grep`](grep.md) | Search text patterns in files | [Open](grep.md) |
| [`sed`](sed.md) | Stream editor for filtering and transforming text | [Open](sed.md) |
| [`awk`](awk.md) | Pattern scanning and text processing language | [Open](awk.md) |

### Archiving & Transfer

| Command | Description | Doc |
|---------|-------------|-----|
| [`tar`](tar.md) | Create and extract archives | [Open](tar.md) |
| [`rsync`](rsync.md) | Fast incremental file sync and backup | [Open](rsync.md) |
| [`ssh`](ssh.md) | Secure remote login and command execution | [Open](ssh.md) |

### System & Service Management

| Command | Description | Doc |
|---------|-------------|-----|
| [`systemctl`](systemctl.md) | Control systemd services and units | [Open](systemctl.md) |
| [`journalctl`](journalctl.md) | Query and view systemd journal logs | [Open](journalctl.md) |

---

## Conventions Used

| Marker | Meaning |
|--------|---------|
| ⚠️ | Destructive or high-risk operation — double-check before running |
| 🔐 | Usually requires root or `sudo` |
| POSIX | Behavior defined by POSIX standard |
| GNU | GNU/coreutils extension (common on Linux) |
| `$` | Run as normal user |
| `#` | Run as root (or via `sudo`) |

---

## Distributions Covered

Examples and notes apply to modern Linux distributions:

- **Debian family:** Ubuntu, Debian
- **RHEL family:** RHEL, Rocky Linux, AlmaLinux, Fedora, CentOS Stream
- **Independent:** Arch Linux

---

## Learning Paths

| Role | Suggested order |
|------|-----------------|
| **Student / beginner** | `ls` → `cp` → `mv` → `grep` → `find` → `tar` |
| **Developer** | `grep` → `sed` → `awk` → `find` → `ssh` → `rsync` |
| **DevOps / SRE** | `systemctl` → `journalctl` → `ssh` → `rsync` → `tar` → `find` |
| **SysAdmin / RHCSA** | All commands, with focus on `systemctl`, `journalctl`, `find`, `tar`, `ssh` |

---

## Contributing

When adding a new command document:

1. Create `docs/linux-commands/<command>.md`
2. Follow the full 20-section template
3. Link it from this README index
4. Prefer practical, production-oriented examples

---

## License

MIT — see [LICENSE](../../LICENSE)
