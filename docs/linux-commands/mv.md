# 1. Command Name

**`mv`** — move (rename) files and directories

- **Syntax**
  ```bash
  mv [OPTION]... [-T] SOURCE DEST
  mv [OPTION]... SOURCE... DIRECTORY
  mv [OPTION]... -t DIRECTORY SOURCE...
  ```
- **Short Description**  
  Renames a file/directory or relocates it to another path. On the same filesystem this is usually a fast metadata operation; across filesystems it copies then removes the source.

---

# 2. Purpose

## Why this command exists
Files need renaming for clarity and relocation for organization, deployment, log rotation patterns, and atomic publish techniques (write temp → `mv` into place).

## What problem it solves
- Rename `file.txt` → `file.md`
- Move files into another directory
- Relocate entire directory trees
- Atomically replace a target on the same filesystem

## When it should be used
- Organizing project structure
- Promoting build artifacts into live paths
- Rotating or archiving logs/configs
- Fixing incorrect names/paths

---

# 3. How it Works

## Internal working
1. **Same filesystem:** typically `rename()` system call — instant, preserves inode; open file descriptors keep working.
2. **Cross filesystem:** equivalent to copy + delete source (data rewrite; not atomic).
3. Destination handling depends on whether DEST exists and is a directory.

## Important concepts
| Concept | Meaning |
|---------|---------|
| **Rename vs move** | Same operation; “move” emphasizes path change |
| **Atomic replace** | On same FS, `mv new current` can replace atomically |
| **Overwrite** | May overwrite existing DEST files (use `-i`/`-n`) |
| **Directory target** | If DEST is directory, sources move *into* it |
| **Permissions** | Need write+execute on source and destination directories |

**POSIX vs GNU:** Core behavior is POSIX; GNU adds `-t`, `-T`, `-u`, `--backup`, etc.

---

# 4. Common Options

| Option | Meaning | Example |
|--------|---------|---------|
| `-i` | Prompt before overwrite | `mv -i a.txt b.txt` |
| `-f` | Force; do not prompt | `mv -f a.txt b.txt` |
| `-n` | No-clobber; never overwrite | `mv -n a.txt b.txt` |
| `-v` | Verbose | `mv -v file /tmp/` |
| `-u` | Move only if source newer or dest missing | `mv -u *.log /var/log/old/` |
| `-t DIR` | Specify target directory (GNU) | `mv -t /archive *.gz` |
| `-T` | Treat DEST as normal file (GNU) | `mv -T mydir mydir.bak` |
| `-b` | Backup existing destinations (GNU) | `mv -b file dest` |
| `--backup=numbered` | Numbered backups (GNU) | `mv --backup=numbered f dest` |

---

# 5. Practical Examples

## Beginner example
```bash
# Rename
mv draft.txt final.txt

# Move into a folder
mv photo.jpg ~/Pictures/
```

## Intermediate example
```bash
# Move multiple files
mv chapter1.md chapter2.md chapter3.md ./book/

# Interactive safety
mv -i production.env production.env.old
```

## Advanced example
```bash
# Atomic publish pattern (same filesystem)
install -m 644 app.conf.new /etc/myapp/app.conf.tmp
mv -f /etc/myapp/app.conf.tmp /etc/myapp/app.conf

# Numbered backups when replacing
mv --backup=numbered site.conf /etc/nginx/conf.d/site.conf
```

## Real-world system administration example
```bash
# Disable a config without deleting (common nginx/httpd pattern)
sudo mv /etc/nginx/conf.d/bad-site.conf /etc/nginx/conf.d/bad-site.conf.disabled
sudo nginx -t && sudo systemctl reload nginx

# Archive old logs by month
sudo mkdir -p /var/log/myapp/2026-07
sudo mv /var/log/myapp/*.log.1 /var/log/myapp/2026-07/
```

⚠️ `mv` can overwrite destinations and can break running services if you move files they depend on.

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `mv` | Rename/relocate; removes from source path | Rename or reorganize |
| `cp` | Duplicates; source remains | Need both copies |
| `rename` | Bulk rename via Perl/util-linux variants | Many systematic renames |
| `rsync --remove-source-files` | Sync then remove sources | Complex selective moves |
| `ln` | Create links without removing source | Multiple names for same data |

**Why prefer `mv`?** Fast same-FS renames and simple mental model. Prefer `cp` when you must keep the original; prefer specialized `rename` for bulk pattern renames.

---

# 7. Advantages

- **Performance:** Near-instant on same filesystem
- **Ease of use:** Minimal syntax
- **Automation:** Atomic replace patterns improve deploy safety
- **Security:** Can quickly quarantine files out of web roots
- **Data integrity:** Same-FS rename does not rewrite file content

---

# 8. Disadvantages

- **Limitations:** Cross-device “move” is not atomic and can leave partial state if interrupted
- **Risks:** Overwrites; moving open libraries/binaries can surprise processes
- **Common mistakes:** `mv file dir` when `dir` is not a directory renames instead
- **Performance issues:** Huge cross-filesystem trees are slow (full copy)

⚠️ There is no trash/recycle bin in core `mv`. Deleted-by-overwrite may be unrecoverable.

---

# 9. Exit Status

| Code | Meaning |
|------|---------|
| `0` | Success |
| `>0` | Failure (missing source, permission, etc.) |

---

# 10. Common Errors

| Error | Why | Fix |
|-------|-----|-----|
| `No such file or directory` | Bad path | Verify with `ls`/`realpath` |
| `Permission denied` | Directory perms / immutable flag | Fix ACLs/modes; check `lsattr` |
| `Device or resource busy` | Mount point / busy path | Unmount or stop using process |
| Unexpected rename | Dest was not a directory | Create dest dir first or use trailing `/` carefully |
| Cross-device failure mid-way | Interrupted copy-delete | Re-run carefully; verify both sides |

---

# 11. Best Practices

- Use `mv -i` interactively on shared systems
- Prefer write-to-temp + `mv` for atomic config updates on same FS
- Avoid moving files out from under package managers without understanding impact
- Quote paths: `mv -- "$src" "$dst"`
- For bulk renames, preview with `echo`/`rename -n` first

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `cp` | Duplicate instead of relocate |
| `rm` | Delete instead of move |
| `mkdir` | Create destination directories |
| `dirname` / `basename` | Build paths in scripts |
| `rsync` | Complex tree relocation |
| `systemctl` | Restart services after moving unit files |

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Rename | `mv old new` |
| Move to dir | `mv file dir/` |
| Multiple into dir | `mv f1 f2 dir/` |
| Interactive | `mv -i src dest` |
| No overwrite | `mv -n src dest` |
| Verbose | `mv -v src dest` |
| Target dir option | `mv -t dir f1 f2` |

---

# 14. Interview Questions

## Beginner
1. How do you rename a file in Linux?  
2. What happens if destination exists?

## Intermediate
3. Same-filesystem vs cross-filesystem `mv` behavior?  
4. How can `mv` help atomic deployments?

## Advanced
5. Why might a process still read a file after it was `mv`’d away?  
6. How do directory write permissions affect `mv`?

---

# 15. Exam Notes

- `mv` renames/moves; does not create a second copy on success (source path gone)
- Overwrite behavior and `-i`/`-f`/`-n` are common exam topics
- Atomic rename on same FS is a classic admin technique

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Forms for rename vs move-into-directory |
| **DESCRIPTION** | Overwrite and directory target rules |
| **OPTIONS** | `-i`, `-f`, `-n`, `-t`, `-T` |

```bash
man mv
```

---

# 17. Shell Compatibility

Works as an external binary in **Bash, Zsh, Fish, Dash, BusyBox** (BusyBox options may be limited).

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Atomic release symlink/dir switch |
| **Embedded** | Move firmware blob into place |
| **Cloud** | Relocate logs to attached volume |
| **Server Admin** | Disable configs by renaming `.conf` → `.disabled` |
| **Cybersecurity** | Quarantine malware samples out of `$PATH` |
| **Software Dev** | Refactor project folder names |
| **Desktop** | Organize Downloads into folders |

---

# 19. Tips & Tricks

```bash
alias mvi='mv -iv'

# Move all except hidden (bash)
mv -- * /target/ 2>/dev/null

# Ensure DEST is directory
mkdir -p "$dest" && mv -t "$dest" file1 file2
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Rename or relocate files/directories |
| **Most useful options** | `-i`, `-n`, `-v`, `-t`, `-u` |
| **Similar commands** | `cp`, `rename`, `rsync` |
| **Best practices** | Atomic temp+mv; avoid blind overwrite |
| **Common mistakes** | Cross-FS non-atomic moves; wrong dest type |

**Bottom line:** `mv` is rename/relocate — instant on one filesystem, careful and non-atomic across filesystems.
