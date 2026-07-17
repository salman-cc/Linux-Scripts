# 1. Command Name

**`rsync`** — a fast, versatile remote (and local) file-copying tool

- **Syntax**
  ```bash
  rsync [OPTION]... SRC... [USER@]HOST:DEST
  rsync [OPTION]... [USER@]HOST:SRC... [DEST]
  rsync [OPTION]... SRC... DEST
  ```
- **Short Description**  
  Synchronizes files and directories between locations using an efficient delta-transfer algorithm. Supports local copies, remote over SSH, includes/excludes, bandwidth limits, and deletion of extraneous files.

---

# 2. Purpose

## Why this command exists
`cp` and full re-copy of large trees waste time and bandwidth. Systems need incremental, resumable, filterable synchronization for backups and deploys.

## What problem it solves
- Efficiently update destinations to match sources
- Remote copy over SSH without manual tar pipelines
- Selective sync with include/exclude rules
- Mirrors and backup jobs with optional `--delete`

## When it should be used
- Deploying static assets and app releases
- Backing up servers to backup hosts
- Migrating data between machines
- Keeping secondary copies nearly current

---

# 3. How it Works

## Internal working
1. Builds file lists on source (and destination for comparisons).
2. Compares size/time (default) or checksums (`--checksum`).
3. Transfers only changed parts when possible (delta algorithm for local/remote rsync protocol).
4. Over SSH, often runs `rsync` on both ends via remote shell.
5. Optionally removes destination files not present on source (`--delete`).

## Important concepts
| Concept | Meaning |
|---------|---------|
| **Trailing slash** | `src/` copies *contents*; `src` copies the directory node into dest |
| **Delta transfer** | Send differences, not always whole files |
| **Archive mode `-a`** | `-rlptgoD` — recursive + preserve common attrs |
| **Dry run `-n`** | Show what would happen |
| **Remote shell** | Usually `ssh` (`-e ssh`) |
| **Daemon mode** | `host::module` rsync protocol without shell |

**Not POSIX** — `rsync` is a widely installed separate package (often preinstalled on servers).

---

# 4. Common Options

| Option | Meaning | Example |
|--------|---------|---------|
| `-a` | Archive mode | `rsync -a src/ dest/` |
| `-v` | Verbose | `rsync -av src/ dest/` |
| `-z` | Compress during transfer | `rsync -az src/ host:dest/` |
| `-n`, `--dry-run` | Simulate | `rsync -avn src/ dest/` |
| `-P` | `--partial --progress` | `rsync -aP big/ host:backup/` |
| `-h` | Human-readable numbers | `rsync -ah src/ dest/` |
| `--delete` | Remove dest files not in src | `rsync -a --delete src/ dest/` |
| `--exclude=PAT` | Skip matching paths | `rsync -a --exclude='.git' src/ dest/` |
| `--include=PAT` | Include pattern | with exclude chains |
| `-e ssh` | Remote shell | `rsync -e 'ssh -p 2222' ...` |
| `-x` | Don’t cross filesystem boundaries | `rsync -ax / /mnt/backup/` |
| `--bwlimit=RATE` | Bandwidth limit (KB/s) | `rsync --bwlimit=5000 ...` |
| `-u` | Skip files newer on receiver | `rsync -au src/ dest/` |
| `--chmod` | Apply permission map | advanced deploys |
| `-S` | Sparse file handling | VM images |
| `--link-dest=DIR` | Hardlink-based snapshots | efficient backup rotations |
| `-A` / `-X` | Preserve ACLs / xattrs | when needed |

---

# 5. Practical Examples

## Beginner example
```bash
# Local sync of a folder
rsync -av ~/Documents/ ~/Backup/Documents/
```

## Intermediate example
```bash
# Dry-run a deploy first
rsync -avn --delete ./build/ user@web01:/var/www/app/

# Real deploy after review
rsync -av --delete ./build/ user@web01:/var/www/app/
```

## Advanced example
```bash
# Exclude caches; compress; show progress
rsync -azP \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='*.tmp' \
  ./myapp/ deploy@10.0.0.12:/opt/myapp/

# Snapshot-style backup with hardlinks (space efficient)
# Assume previous snapshot at backup/2026-07-16
rsync -aH --delete --link-dest=../2026-07-16 \
  /srv/data/ /backup/2026-07-17/
```

## Real-world system administration example
```bash
# 🔐 Nightly backup of /etc and /home over SSH
rsync -az --delete \
  --exclude='.cache' \
  -e 'ssh -i /root/.ssh/backup_key' \
  /etc /home backup@backup-host:/backups/$(hostname)/

# Migrate website data between servers
rsync -aHAX --numeric-ids --info=progress2 \
  /var/www/ root@new-server:/var/www/
```

⚠️ **`--delete` can wipe the destination.** Always dry-run (`-n`) first and double-check trailing slashes.

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `rsync` | Incremental sync, filters, remote | Backups, deploys, mirrors |
| `cp -a` | Full local copy each time | Simple one-shot local duplicates |
| `scp` | Whole-file remote copy | Single files; simpler but less efficient |
| `sftp` | Interactive remote file transfer | Manual transfers |
| `tar` over `ssh` | Stream archive | One-shot snapshots |
| `rclone` | Cloud object storage focus | S3/GCS/Azure blobs |

**Why prefer `rsync`?** Best default for repeated syncs and controlled deploys. Prefer `scp` only for tiny ad-hoc copies; `rclone` for cloud object stores.

---

# 7. Advantages

- **Performance:** Transfers deltas; can resume partial files
- **Ease of use:** One tool for local and remote
- **Automation:** Cron-friendly; excellent exit status usage
- **Security:** Works over SSH; key-based automation
- **Flexibility:** Includes/excludes, bandwidth limits, link-dest snapshots

---

# 8. Disadvantages

- **Limitations:** Destination can be destroyed with `--delete`; not a full VCS
- **Risks:** Wrong trailing slash; syncing to empty/wrong path
- **Common mistakes:** Forgetting dry-run; excluding too little/much
- **Performance issues:** Huge file trees listing phase can be slow; `-z` may hurt on fast LAN/CPU-bound links

---

# 9. Exit Status

| Code | Meaning (common) |
|------|------------------|
| `0` | Success |
| `1`–`30+` | Various errors (syntax, protocol, partial transfer, timeout, etc.) |

Scripts should treat non-zero as failure and alert. See `man rsync` “EXIT VALUES”.

---

# 10. Common Errors

| Error | Why | Fix |
|-------|-----|-----|
| `Permission denied (publickey)` | SSH auth failed | Fix keys/`ssh` config |
| `rsync: command not found` on remote | rsync missing remote | Install `rsync` both sides |
| Unexpected nested directory | Trailing slash misuse | Review `src` vs `src/` |
| Deleted too much | `--delete` + wrong src | Restore from backup; always `-n` |
| Slow transfers | Compression/CPU or latency | Tune `-z`, `--bwlimit`, network |

---

# 11. Best Practices

- **Always dry-run** critical jobs with `-n`
- Master trailing-slash semantics before using `--delete`
- Prefer SSH keys with restricted commands for backup accounts
- Log output of cron rsync jobs
- Use `--exclude` for caches, tmp, secrets not meant for target
- Test restores, not only successful sync exit codes
- Consider `--link-dest` for retention without full duplicate space

```bash
rsync -avn --delete src/ dest/ | less   # review first
```

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `ssh` | Remote transport |
| `cp` | Simple local alternative |
| `tar` | Snapshot archives |
| `find` | Select/verify files |
| `df`/`du` | Capacity planning |
| `systemctl` / cron / systemd timers | Schedule syncs |

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Local archive sync | `rsync -a src/ dest/` |
| Verbose + human | `rsync -avh src/ dest/` |
| Dry run | `rsync -avn src/ dest/` |
| Remote over SSH | `rsync -az src/ user@host:dest/` |
| Progress + partial | `rsync -aP src/ dest/` |
| Mirror delete | `rsync -a --delete src/ dest/` |
| Exclude git | `rsync -a --exclude='.git' src/ dest/` |
| Specific ssh port | `rsync -e 'ssh -p 2222' ...` |

---

# 14. Interview Questions

## Beginner
1. What is rsync used for?  
2. What does `-a` mean?

## Intermediate
3. Explain trailing slash behavior.  
4. What does `--delete` do and what is the danger?  
5. How do you do a dry run?

## Advanced
6. How does `--link-dest` enable efficient snapshots?  
7. When is `-z` harmful?  
8. Difference between `rsync` over SSH and rsync daemon mode?

---

# 15. Exam Notes

- Common in RHCSA/RHCE-style backup and transfer tasks
- Know `-a`, `-v`, `-z`, `--delete`, excludes, SSH usage
- Trailing slash questions appear in interviews often

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Local and remote forms |
| **DESCRIPTION** | Algorithm overview |
| **OPTIONS** | Extensive flag reference |
| **USAGE** | Trailing slash rules (critical) |
| **EXIT VALUES** | Detailed codes |
| **EXAMPLES** | Practical patterns |

```bash
man rsync
```

---

# 17. Shell Compatibility

Works from **Bash, Zsh, Fish, Dash** as an external program.  
Must be installed on local and (for remote rsync protocol efficiency) remote systems. Not a BusyBox core applet on many devices (may need full rsync package).

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Blue/green static asset sync to fleets |
| **Embedded** | Push updated app trees to devices over SSH |
| **Cloud** | Sync data disks between instances |
| **Server Admin** | Nightly home/etc backups |
| **Cybersecurity** | Collect forensic copies with attribute preservation |
| **Software Dev** | Deploy build directories |
| **Desktop** | Sync projects to NAS |

---

# 19. Tips & Tricks

```bash
# Itemize changes (see exactly what transfers)
rsync -ai src/ dest/

# Partial progress modern output
rsync -a --info=progress2 src/ dest/

# Copy one file efficiently
rsync -avP large.iso user@host:/data/

# Limit bandwidth during business hours
rsync -az --bwlimit=2000 src/ backup:/data/
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Efficient local/remote synchronization |
| **Most useful options** | `-a`, `-v`, `-z`, `-n`, `-P`, `--delete`, `--exclude` |
| **Similar commands** | `cp`, `scp`, `tar|ssh`, `rclone` |
| **Best practices** | Dry-run; respect trailing slashes; secure SSH |
| **Common mistakes** | `--delete` disasters; wrong slash; missing remote rsync |

**Bottom line:** `rsync -av` is the default professional copy/sync tool; add `-n` before any destructive flag.
