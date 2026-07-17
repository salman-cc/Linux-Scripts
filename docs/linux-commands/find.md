# 1. Command Name

**`find`** — search for files in a directory hierarchy

- **Syntax**

  ```bash
  find [-H] [-L] [-P] [path...] [expression]
  ```

- **Short Description**  
  Walks directory trees and selects files based on name, type, size, time, permissions, ownership, and more — then prints them or runs actions (`-exec`, `-delete`).

---

# 2. Purpose

## Why this command exists

Real systems have thousands to millions of files. Manual browsing with `ls` does not scale; admins need predicate-based search and bulk actions.

## What problem it solves

- Locate files by name/path pattern
- Find large, old, empty, or permission-sensitive files
- Apply commands to matching sets safely
- Inventory systems for audits and cleanups

## When it should be used

- Disk cleanup (`-size`, `-mtime`)
- Security audits (SUID, world-writable)
- Build/deploy artifact cleanup
- Pre-backup selection and reporting

---

# 3. How it Works

## Internal working

1. Starts at given path(s) (default `.`).
2. Recursively descends directories (unless pruned).
3. Evaluates an expression tree of tests and actions.
4. Default action is `-print` if none specified.
5. Respects symlink policy (`-P` default: don’t follow).

## Important concepts

| Concept | Meaning |
|---------|---------|
| **Tests** | `-name`, `-type`, `-mtime`, `-size`, … |
| **Operators** | `-a` (and), `-o` (or), `!` / `-not`, parentheses `\(` `\)` |
| **Actions** | `-print`, `-print0`, `-exec`, `-ok`, `-delete` |
| **Pruning** | `-prune` skips descending into a directory |
| **Time bases** | `-mtime` (days), `-mmin` (minutes); atime/ctime variants |
| **`-exec` forms** | `{} \;` one-by-one; `{} +` batched (faster) |

**POSIX vs GNU:** `find` is POSIX; GNU findutils adds many tests (`-regex`, `-printf`, `-iname` portability varies — `-iname` is common on Linux).

---

# 4. Common Options / Expression Primaries

| Option / test | Meaning | Example |
|---------------|---------|---------|
| `-name pattern` | Basename glob match | `find . -name '*.log'` |
| `-iname pattern` | Case-insensitive name | `find . -iname 'readme*'` |
| `-path pattern` | Full path glob | `find / -path '*/.git/*' -prune -o -print` |
| `-type f/d/l` | File / directory / symlink | `find /etc -type f` |
| `-size +N` | Size larger than N (`c` bytes, `k`, `M`, `G`) | `find / -type f -size +100M` |
| `-mtime -N` | Modified within N days | `find . -mtime -1` |
| `-mmin -N` | Modified within N minutes | `find /var/log -mmin -30` |
| `-user name` | Owned by user | `find /home -user alice` |
| `-group name` | Owned by group | `find /srv -group dev` |
| `-perm mode` | Permission match | `find / -perm -4000` (SUID) |
| `-empty` | Empty file or dir | `find . -type d -empty` |
| `-maxdepth N` | Limit descent depth | `find /etc -maxdepth 1 -type f` |
| `-mindepth N` | Start actions at depth | `find . -mindepth 1 -maxdepth 2` |
| `-prune` | Do not descend | see examples |
| `-print0` | NUL-delimited paths | safe with `xargs -0` |
| `-exec cmd {} \;` | Run command per file | `find . -name '*.tmp' -exec rm {} \;` |
| `-exec cmd {} +` | Batched exec | `find . -name '*.c' -exec grep -H TODO {} +` |
| `-delete` | Delete matches (careful) | `find /tmp -type f -mtime +7 -delete` |
| `-ls` | `ls -dils` style listing | `find . -name core -ls` |
| `-printf format` | Custom output (GNU) | `find . -printf '%p %s\n'` |

---

# 5. Practical Examples

## Beginner example

```bash
# All .txt files under home
find ~ -type f -name '*.txt'

# List directories only one level under /etc
find /etc -maxdepth 1 -type d
```

## Intermediate example

```bash
# Files modified in last 24 hours
find /var/log -type f -mtime -1

# Large files for disk investigation (may need 🔐)
sudo find /var -type f -size +500M -ls 2>/dev/null

# Empty directories
find /opt/myapp -type d -empty
```

## Advanced example

```bash
# Safe delete of old temp files (NUL-safe pipeline alternative)
find /tmp -type f -mtime +7 -print0 | xargs -0 --no-run-if-empty rm -f

# SUID/SGID audit
sudo find / -xdev \( -perm -4000 -o -perm -2000 \) -type f -ls 2>/dev/null

# Skip .git and node_modules while searching names
find . \( -name .git -o -name node_modules \) -prune -o -type f -name '*.js' -print
```

## Real-world system administration example

```bash
# Cleanup old application logs older than 30 days
sudo find /var/log/myapp -type f -name '*.log' -mtime +30 -delete

# Find world-writable files (security hardening review)
sudo find / -xdev -type f -perm -0002 -ls 2>/dev/null | head

# Pre-backup: list files changed in last day under /etc
sudo find /etc -type f -mtime -1 -print
```

⚠️ **`-delete` and `-exec rm` are destructive.** Test with `-print` first. Prefer `-xdev` to avoid crossing into other mounts unexpectedly.

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `find` | Full expression language + actions | Complex search & bulk ops |
| `ls -R` | Simple recursive list | Quick human browsing |
| `locate` / `plocate` | DB-backed name search | Fast name lookup if DB fresh |
| `fd` | Modern UX alternative | Interactive dev machines |
| `tree` | Visual hierarchy | Structure overview |
| `grep -r` | Content search | When looking inside file data |

**Why prefer `find`?** Precise filters (time/size/perm) and safe bulk actions. Use `locate` for quick name-only queries; `grep -r` for content.

---

# 7. Advantages

- **Performance:** Can limit scope with `-maxdepth`, `-xdev`, `-prune`
- **Ease of use:** Once expression syntax is learned, extremely powerful
- **Automation:** Backbone of cleanup cron jobs and audits
- **Security:** Locate risky permissions and orphaned files
- **Correctness:** `-print0` enables safe handling of weird filenames

---

# 8. Disadvantages

- **Limitations:** Expression precedence confuses beginners
- **Risks:** Destructive actions; scanning `/` is heavy
- **Common mistakes:** Unquoted `*`; wrong `-mtime` units; `-exec` without `{}`
- **Performance issues:** Full-tree walks on large NAS/container layers

---

# 9. Exit Status

| Code | Meaning |
|------|---------|
| `0` | All path arguments were walked successfully (even if zero matches) |
| `>0` | Errors occurred (permission denied paths, invalid expression, etc.) |

Note: zero matches still often yields exit 0 — unlike `grep`.

---

# 10. Common Errors

| Error / issue | Why | Fix |
|---------------|-----|-----|
| `Permission denied` | Unreadable dirs | `sudo` or redirect stderr |
| Unexpected huge results | Too broad path | Add `-maxdepth`, path roots, tests |
| Glob expanded by shell | Unquoted `*.log` | Quote: `'*.log'` |
| Deleted wrong files | No dry-run | Always `-print` first |
| `-mtime +1` confusion | Rounding in 24h periods | Read man carefully; use `-mmin` |

---

# 11. Best Practices

- **Dry-run first:** `find ... -print` before `-delete`/`rm`
- Quote patterns: `-name '*.log'`
- Prefer `-exec ... {} +` or `-print0 | xargs -0` for speed/safety
- Use `-xdev` when auditing a single filesystem
- Limit production scans during peak hours
- Log what you delete in maintenance scripts

```bash
# Safe pattern
find /var/tmp -type f -mtime +14 -print
# after review:
find /var/tmp -type f -mtime +14 -print0 | xargs -0 rm -f
```

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `xargs` | Consume `-print0` lists |
| `grep` | Search inside files found |
| `chmod`/`chown` | Fix permissions on matches |
| `du` | Measure space after finding large dirs |
| `tar` | Archive matches |
| `rsync` | Sync selected trees |
| `stat` | Inspect a found path |

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| By name | `find . -name '*.conf'` |
| By type file | `find . -type f` |
| Depth limit | `find /etc -maxdepth 2` |
| Modified 7+ days ago | `find . -mtime +7` |
| Larger than 100MB | `find . -size +100M` |
| Empty dirs | `find . -type d -empty` |
| Exec command | `find . -name '*.bak' -exec rm {} +` |
| NUL-safe list | `find . -print0` |
| Don’t cross mounts | `find / -xdev ...` |
| SUID files | `find / -perm -4000 -type f` |

---

# 14. Interview Questions

## Beginner

1. How do you find all `.log` files under `/var`?  
2. What does `-type d` mean?

## Intermediate

3. Difference between `-mtime -1` and `-mtime +1`?  
4. How does `-exec ... {} \;` differ from `{} +`?  
5. How do you exclude a directory from descent?

## Advanced

6. Explain `-perm -4000` vs `-perm /4000` (GNU).  
7. Why is `-print0` important?  
8. How do you find files with no owner (`-nouser`)?

---

# 15. Exam Notes

| Exam | Focus |
|------|-------|
| **RHCSA** | Locate files; size/time; permissions; SUID |
| **LPIC** | Expression syntax; `-exec`; operators |
| **Linux+** | Basic find by name/type |
| **DevOps** | Cleanup jobs; artifact search |

**Critical:** Quote wildcards; understand day-based time tests; know default `-print`.

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Paths + expression |
| **DESCRIPTION** | Walk model and expression evaluation |
| **OPTIONS** | `-H/-L/-P` symlink handling |
| **EXPRESSION** | Tests, actions, operators (main content) |
| **EXAMPLES** | Valuable real patterns |

```bash
man find
```

---

# 17. Shell Compatibility

External utility works in **Bash, Zsh, Fish, Dash**.  
**BusyBox find** supports a subset — verify advanced primaries on embedded devices.

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Delete old CI workspace artifacts |
| **Embedded** | Find large cores filling limited flash |
| **Cloud** | Locate leftover volumes data under `/mnt` |
| **Server Admin** | Temp file cleanup cron |
| **Cybersecurity** | World-writable and SUID audits |
| **Software Dev** | Find all `package.json` in monorepo |
| **Desktop** | Find downloads larger than 1GB |

---

# 19. Tips & Tricks

```bash
# Newest-ish candidates (GNU printf + sort)
find . -type f -printf '%T@ %p\n' | sort -nr | head

# Parallel checksums (example)
find . -type f -print0 | xargs -0 -P4 sha256sum

# Only files owned by deleted users
sudo find / -xdev -nouser -o -nogroup 2>/dev/null
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Predicate search + bulk actions on file trees |
| **Most useful options** | `-name`, `-type`, `-mtime`, `-size`, `-maxdepth`, `-exec`, `-print0`, `-xdev` |
| **Similar commands** | `locate`, `grep -r`, `fd`, `ls -R` |
| **Best practices** | Dry-run; quote globs; NUL-safe pipelines |
| **Common mistakes** | Destructive `-delete` without test; unquoted `*` |

**Bottom line:** `find` is the Swiss Army knife for filesystem queries — print first, act second.
