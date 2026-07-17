# 1. Command Name

**`cp`** — copy files and directories

- **Syntax**

  ```bash
  cp [OPTION]... [-T] SOURCE DEST
  cp [OPTION]... SOURCE... DIRECTORY
  cp [OPTION]... -t DIRECTORY SOURCE...
  ```

- **Short Description**  
  Creates a duplicate of files or directory trees at a new location. Source content is read and written to the destination; originals remain unless you remove them separately.

---

# 2. Purpose

## Why this command exists

Systems constantly need duplicates: backups, staging configs, deploying artifacts, cloning templates, and recovering from mistakes without destroying the original.

## What problem it solves

- Duplicate a file under a new name or path
- Copy many files into a directory
- Recursively copy trees (`-r` / `-R` / `-a`)
- Preserve attributes (mode, ownership, timestamps) when required

## When it should be used

- Creating backups before edits
- Deploying static files to a target host path
- Seeding project skeletons
- Copying between mount points on the same machine

For efficient remote or incremental copies, prefer `rsync` (see [rsync.md](rsync.md)).

---

# 3. How it Works

## Internal working

1. Opens the source file(s).
2. Creates or truncates the destination (depending on options and existing files).
3. Reads source data in blocks and writes to destination.
4. Optionally applies metadata (`fchmod`, `fchown`, timestamps via `utimensat`, xattrs, ACLs).
5. For directories, walks the tree and repeats for each entry.

## Important concepts

| Concept | Meaning |
|---------|---------|
| **Overwrite** | By default, existing DEST files may be overwritten |
| **Recursive** | Directory copy requires `-r`/`-R`/`-a` |
| **Archive mode (`-a`)** | Roughly `-dR --preserve=all` (GNU): preserve + recursive + no-dereference defaults |
| **Dereference** | Whether to follow symlinks or copy the link itself |
| **Sparse files** | Files with holes; special handling may be needed |
| **Cross-filesystem** | Always a full data copy (not a rename) |

**POSIX vs GNU:** Basic `cp` is POSIX; GNU coreutils adds `-a`, `--reflink`, `--preserve=`, progress-related behaviors, etc.

---

# 4. Common Options

| Option | Meaning | Example |
|--------|---------|---------|
| `-r`, `-R` | Copy directories recursively | `cp -r src/ dest/` |
| `-a` | Archive mode (recursive + preserve) | `cp -a /etc/nginx /backup/` |
| `-i` | Interactive: prompt before overwrite | `cp -i file.txt /tmp/` |
| `-f` | Force (may remove existing dest if needed) | `cp -f a b` |
| `-n` | No-clobber: never overwrite | `cp -n src dest` |
| `-u` | Copy only when source is newer or dest missing | `cp -u *.conf /etc/myapp/` |
| `-v` | Verbose: show files copied | `cp -v file /tmp/` |
| `-p` | Preserve mode, ownership, timestamps | `cp -p secret.key /secure/` |
| `-l` | Hard link instead of copy (same filesystem) | `cp -l a b` |
| `-s` | Symbolic link instead of copy | `cp -s /opt/app/bin/tool ~/bin/tool` |
| `-L` | Always follow symlinks in source | `cp -L -r tree/ out/` |
| `-P` | Never follow symlinks in source | `cp -P -r tree/ out/` |
| `-t DIR` | Target directory first (GNU) | `cp -t /backup f1 f2` |
| `-T` | Treat DEST as a normal file (GNU) | `cp -T srcfile destfile` |
| `--reflink=auto` | Copy-on-write clone if FS supports (GNU/Btrfs/XFS) | `cp --reflink=auto big.img clone.img` |

---

# 5. Practical Examples

## Beginner example

```bash
# Copy a single file
cp notes.txt notes.bak

# Copy into a directory
cp report.pdf ~/Documents/
```

## Intermediate example

```bash
# Recursive copy of a project (simple)
cp -r myproject myproject-backup

# Preserve attributes (good for configs)
cp -p /etc/ssh/sshd_config /root/sshd_config.bak

# Prompt before overwriting
cp -i important.conf /etc/myapp/important.conf
```

## Advanced example

```bash
# Archive-style backup of nginx config tree
cp -a /etc/nginx /var/backups/nginx-$(date +%F)

# Update only newer files into a staging area
cp -au build/artifacts/. /var/www/staging/

# Prefer CoW clone when available (fast “copy” on Btrfs)
cp --reflink=auto -a /vm/disk.qcow2 /vm/disk-clone.qcow2
```

## Real-world system administration example

```bash
# Before editing a production config (🔐 may need sudo)
sudo cp -a /etc/fstab /etc/fstab.bak.$(date +%Y%m%d%H%M%S)
sudo vi /etc/fstab

# Seed default app config if missing
if [ ! -f /etc/myapp/app.env ]; then
  sudo cp -a /usr/share/myapp/app.env.example /etc/myapp/app.env
fi
```

⚠️ Recursive copy into the wrong destination can nest trees (`src` becomes `dest/src`) or overwrite live configs. Always confirm paths.

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `cp` | Full copy of data locally | Simple duplicates, one-shot copies |
| `mv` | Moves/renames; may not duplicate data | Relocate or rename |
| `rsync` | Incremental, remote, filters, resume | Backups, deploys, large trees |
| `install` | Copy with mode/owner set; used by packages | Install binaries/configs with known modes |
| `dd` | Block-level copy | Disks, images, special devices |
| `tar` + pipe | Stream trees with attributes | Network copy patterns, archiving |

**Why prefer one over another?**  

- **`cp`**: simplest local copy.  
- **`rsync`**: large/incremental/remote or need `--delete`.  
- **`install`**: set permissions in one step for deployed files.  
- **`dd`**: raw devices — not general file trees.

---

# 7. Advantages

- **Performance:** Efficient for small/medium local copies; reflink can be near-instant
- **Ease of use:** Simple two-argument mental model
- **Automation:** Easy in shell scripts and CI
- **Security:** `-p`/`-a` help retain restrictive modes on sensitive files
- **Availability:** Coreutils on all major distros

---

# 8. Disadvantages

- **Limitations:** No built-in remote transfer; weak incremental logic vs `rsync`
- **Risks:** Silent overwrite (without `-i`/`-n`); recursive mistakes
- **Common mistakes:** Forgetting `-r` for directories; `cp file dir` vs unintended rename
- **Performance issues:** Full re-copy of huge trees every time; metadata-heavy `-a` on millions of files

⚠️ Overwriting production configs without a backup is a common outage cause.

---

# 9. Exit Status

| Code | Meaning |
|------|---------|
| `0` | All files copied successfully |
| `>0` | Error (permission, missing source, I/O error, etc.) |

```bash
cp missing.txt /tmp/
echo $?   # non-zero
```

---

# 10. Common Errors

| Error | Why it occurs | How to fix |
|-------|---------------|------------|
| `cp: omitting directory 'dir'` | Directory without `-r`/`-a` | Add `-r` or `-a` |
| `Permission denied` | No read on source or write on dest | Fix perms or use `sudo` carefully |
| `No such file or directory` | Missing source or parent of dest | Create parent dirs (`mkdir -p`) |
| Accidental nested directory | Dest existed as directory | Review trailing slashes and dest type |
| Ownership not preserved | Non-root cannot `chown` | Run with privileges if required |

---

# 11. Best Practices

- Prefer **`cp -a`** for config/backup trees when you need fidelity
- Use **`cp -i`** or **`cp -n`** in interactive/admin safety workflows
- Timestamp backups: `file.bak.$(date +%F)`
- For deploys and mirrors, prefer **`rsync -a`**
- Never run recursive copy as root without verifying paths
- Test with `-v` first on critical operations

```bash
# Safe-ish pattern
sudo cp -an /etc/myapp/myapp.conf /etc/myapp/myapp.conf.bak
```

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `mkdir -p` | Create destination parents |
| `rsync` | Advanced copy/sync |
| `mv` | Relocate after copy validation |
| `chmod` / `chown` | Fix attributes after copy |
| `diff` / `cmp` | Verify copies |
| `tar` | Archive before bulk copy |
| `sha256sum` | Integrity check after copy |

```bash
cp -a app.conf app.conf.bak
diff -u app.conf.bak app.conf
```

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Copy file | `cp src dest` |
| Copy into directory | `cp file dir/` |
| Recursive | `cp -r src/ dest/` |
| Preserve all (GNU archive) | `cp -a src dest` |
| Interactive overwrite | `cp -i src dest` |
| No overwrite | `cp -n src dest` |
| Verbose | `cp -v src dest` |
| Update if newer | `cp -u src dest` |
| Backup configs | `cp -a /etc/x /backup/x` |

---

# 14. Interview Questions

## Beginner

1. How do you copy a directory with `cp`?  
2. What does `cp file1 file2` do if `file2` exists?

## Intermediate

3. Difference between `cp -r` and `cp -a`?  
4. How do you prevent overwriting existing files?  
5. What is preserved by `cp -p`?

## Advanced

6. How do symlinks behave with `-P` vs `-L`?  
7. What is reflink copy and when does it help?  
8. Why might `cp -a` fail to preserve ownership for a normal user?

---

# 15. Exam Notes

| Exam | Focus |
|------|-------|
| **RHCSA** | Copy files/dirs; preserve attributes; backup before edit |
| **LPIC-1** | `cp` options; recursive; permissions impact |
| **Linux+** | Basic file management |
| **DevOps** | When to use `cp` vs `rsync`/`install` |

Remember: **directories need recursive flags**; **`-a` is preferred for faithful backups** on GNU systems.

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Three usage forms (to file, to dir, `-t`) |
| **DESCRIPTION** | Overwrite rules and trailing slash behavior |
| **OPTIONS** | `-a`, `-r`, `-i`, preserve flags |
| **AUTHOR / SEE ALSO** | Related coreutils tools |

```bash
man cp
```

---

# 17. Shell Compatibility

| Environment | Notes |
|-------------|-------|
| **Bash / Zsh / Fish / Dash** | External `/bin/cp` works in all |
| **BusyBox** | Smaller option set; verify `-a` availability |

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Copy build artifacts into image context |
| **Embedded** | Install rootfs overlays with `cp -a` |
| **Cloud** | Copy cloud-init snippets into `/var/lib/cloud` |
| **Server Admin** | Backup `/etc` files before package upgrades |
| **Cybersecurity** | Quarantine copies of suspicious files for analysis |
| **Software Dev** | Duplicate `.env.example` → `.env` |
| **Desktop** | Copy photos to external media |

---

# 19. Tips & Tricks

```bash
# Copy contents of src into dest (not the directory node itself)
cp -a src/. dest/

# Parent directories must exist
mkdir -p /backup/etc && cp -a /etc/hosts /backup/etc/

# Verbose + interactive safety
alias cpi='cp -iv'

# Compare after copy
cmp original copy && echo OK
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Duplicate files and trees locally |
| **Most useful options** | `-a`, `-r`, `-i`, `-n`, `-v`, `-u`, `-p` |
| **Similar commands** | `rsync`, `mv`, `install`, `dd` |
| **Best practices** | Backup before overwrite; prefer `-a` for fidelity |
| **Common mistakes** | Forgetting `-r`; silent overwrite; wrong dest nesting |

**Bottom line:** Use `cp` for straightforward local copies; escalate to `rsync` for sync, remote, or large incremental jobs.
