# 1. Command Name

**`sed`** — stream editor for filtering and transforming text

- **Syntax**

  ```bash
  sed [OPTION]... {script-only-if-no-other-script} [input-file]...
  sed [OPTION]... -e script ... [input-file]...
  sed [OPTION]... -f script-file ... [input-file]...
  ```

- **Short Description**  
  Reads text stream line by line, applies editing commands (substitute, delete, print, insert, etc.), and writes the result. Famous for non-interactive search-and-replace.

---

# 2. Purpose

## Why this command exists

Admins and developers must transform configs, logs, and data streams without opening a full editor — especially in pipelines and automation.

## What problem it solves

- Replace text patterns across files
- Delete or print selected lines
- In-place config edits in scripts
- Lightweight text ETL in shell pipelines

## When it should be used

- Bulk string replacement
- Cleaning command output
- Automated config templating (simple cases)
- One-liners in CI/CD

For complex field-oriented processing, prefer `awk`. For interactive edits, use `vim`/`nano`.

---

# 3. How it Works

## Internal working

1. Reads a line into the **pattern space**.
2. Applies sed script commands to the pattern space.
3. By default prints the pattern space (unless `-n`).
4. Repeats until EOF.
5. Optional **hold space** stores text across lines for advanced scripts.

## Important concepts

| Concept | Meaning |
|---------|---------|
| **Pattern space** | Working buffer for current line |
| **Hold space** | Auxiliary buffer |
| **`s///`** | Substitute command |
| **Address** | Line number or regex selecting lines |
| **BRE/ERE** | Default basic regex; `-E`/`-r` extended |
| **In-place (`-i`)** | Edit files on disk (GNU/BSD differ!) |

**POSIX vs GNU:** `sed` is POSIX; GNU sed adds `-i`, `-r`/`-E` nuances, more escapes; BSD/macOS `-i` requires backup-arg syntax differences — important for portable scripts.

---

# 4. Common Options

| Option | Meaning | Example |
|--------|---------|---------|
| `-e script` | Add editing command | `sed -e 's/a/b/' -e 's/c/d/' f` |
| `-f file` | Read script from file | `sed -f edits.sed input` |
| `-n` | Quiet; only explicit `p` prints | `sed -n '10,20p' file` |
| `-i[SUFFIX]` | In-place edit (GNU) | `sed -i 's/foo/bar/' file` |
| `-i SUFFIX` | In-place with backup (portable care) | `sed -i.bak 's/foo/bar/' file` |
| `-E` / `-r` | Extended regex (GNU: both) | `sed -E 's/[0-9]+/N/g'` |
| `-z` | NUL-separated records (GNU) | multi-line-ish processing |

## Common script commands

| Command | Meaning | Example |
|---------|---------|---------|
| `s/pat/rep/` | Substitute first match | `sed 's/error/Error/'` |
| `s/pat/rep/g` | Substitute all on line | `sed 's/foo/bar/g'` |
| `s/pat/rep/i` | Case-insensitive (GNU) | `sed 's/error/ERR/gi'` |
| `d` | Delete line | `sed '/^#/d'` |
| `p` | Print line | `sed -n '/TODO/p'` |
| `a\text` | Append after | `sed '/end/a\newline'` |
| `i\text` | Insert before | `sed '1i\header'` |
| `c\text` | Replace line | `sed '/old/c\new line'` |
| `q` | Quit | `sed '10q'` |
| `y/abc/xyz/` | Transliterate | `sed 'y/abc/ABC/'` |

---

# 5. Practical Examples

## Beginner example

```bash
# Replace first "http" with "https" on each line
sed 's/http/https/' urls.txt

# Delete blank lines
sed '/^$/d' file.txt
```

## Intermediate example

```bash
# Global replace
sed 's/foo/bar/g' app.conf

# Print only matching lines (like grep)
sed -n '/error/p' app.log

# Remove comment lines starting with #
sed '/^#/d' config.ini
```

## Advanced example

```bash
# Capture groups (ERE)
sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[IP]/Dacted]/g' access.log

# In-place with backup (safer)
sudo sed -i.bak 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Multiple commands
sed -e '/^#/d' -e '/^$/d' -e 's/[[:space:]]*$//' messy.conf
```

## Real-world system administration example

```bash
# 🔐 Disable a systemd service unit WantedBy line carefully (prefer systemctl tools when possible)
# Example: change a config value in a simple key=value file
sudo cp -a /etc/myapp/app.env /etc/myapp/app.env.bak
sudo sed -i 's/^LOG_LEVEL=.*/LOG_LEVEL=info/' /etc/myapp/app.env

# Bulk rename host references in inventory
sed -i 's/old-host\.example\.com/new-host.example.com/g' inventory.ini
```

⚠️ **In-place edits on production configs are risky.** Always backup first (`cp -a` or `sed -i.bak`). Prefer templating systems (Ansible, confd) for complex fleets.

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `sed` | Stream line editor | Substitutions, deletions, simple transforms |
| `awk` | Field-aware programming language | Columns, reports, calculations |
| `grep` | Filter matches only | Search without rewriting |
| `perl -pe` | Powerful regex/text Swiss army | Complex multi-line / Unicode cases |
| `tr` | Character translation only | Squeeze/delete chars |
| `cut` | Field cut by delimiter | Simple column extraction |

**Why prefer `sed`?** Perfect for `s///` and address-based line edits in pipelines. Prefer `awk` for fields; `grep` when you only need to filter.

---

# 7. Advantages

- **Performance:** Streams data; low memory for large files
- **Ease of use:** Common substitutions are short one-liners
- **Automation:** Ideal for shell scripts and package maintainer scripts
- **Security:** Can strip secrets from logs before sharing (with care)
- **Ubiquity:** Available on essentially all Unix systems

---

# 8. Disadvantages

- **Limitations:** Multi-line logic is hard; syntax is terse and error-prone
- **Risks:** `-i` without backup; greedy regex over-matching
- **Common mistakes:** Forgetting `g`; wrong delimiter with paths (`/`)
- **Performance issues:** Complex scripts may be clearer/faster in `awk`/`perl`

Delimiter tip: `sed 's|/usr/local|/opt|g'` avoids escaping slashes.

---

# 9. Exit Status

| Code | Meaning |
|------|---------|
| `0` | Success |
| `>0` | Invalid option, cannot open file, or script error |

Note: Unlike `grep`, “no substitution occurred” is still usually success.

---

# 10. Common Errors

| Error / symptom | Why | Fix |
|-----------------|-----|-----|
| No change observed | Pattern not matched / missing `g` | Test with `sed -n 's/p/r/p'` |
| `unterminated address regex` | Bad syntax | Balance delimiters |
| Portable `-i` breakage | GNU vs BSD `-i` | Use `sed -i.bak` form carefully or `perl -pi` |
| Over-replaced text | Too-broad pattern | Anchor with `^` `$` or word boundaries |
| Permission denied | Not writable | `sudo` + backup strategy |

---

# 11. Best Practices

- Backup before in-place edits
- Prefer extended regex `-E` for readability when available
- Use alternate delimiters for paths
- Keep scripts in files (`-f`) when longer than one line
- Validate after edit: `diff -u file.bak file`
- For structured formats (YAML/JSON), use dedicated tools (`yq`, `jq`) instead of fragile sed

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `grep` | Find before transform |
| `awk` | Companion text processor |
| `diff`/`patch` | Review and apply changes |
| `cp` | Backups before `-i` |
| `find` + `sed` | Tree-wide edits |
| `jq`/`yq` | Structured document edits |

```bash
find . -name '*.conf' -print0 | xargs -0 sed -i 's/old/new/g'
```

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Replace first | `sed 's/old/new/' f` |
| Replace all | `sed 's/old/new/g' f` |
| In-place + backup | `sed -i.bak 's/old/new/g' f` |
| Delete matching lines | `sed '/pat/d' f` |
| Print range | `sed -n '1,20p' f` |
| Extended regex | `sed -E 's/[0-9]+/N/g' f` |
| Suppress auto-print | `sed -n 's/p/r/p' f` |
| Path-safe delimiter | `sed 's\|/old\|/new\|g' f` |

---

# 14. Interview Questions

## Beginner

1. How do you replace `foo` with `bar` in a file using sed?  
2. What does the `g` flag mean in `s///g`?

## Intermediate

3. How do you delete all comment lines starting with `#`?  
4. Difference between `sed` and `grep`?  
5. How do addresses work (`/regex/`, line numbers)?

## Advanced

6. Explain pattern space vs hold space.  
7. Portability issues with `sed -i`?  
8. When is `awk` a better choice than `sed`?

---

# 15. Exam Notes

- Know `s/pat/rep/g`, delete, print with `-n`
- Understand BRE basics used by sed
- In-place editing and backup practices appear in admin exams/interviews
- Pipelines: `cmd | sed ...`

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Options and script forms |
| **DESCRIPTION** | Stream editing model |
| **COMMANDS** | `s`, `d`, `p`, etc. |
| **Addresses** | How lines are selected |
| **BUGS / SEE ALSO** | Portability notes |

```bash
man sed
info sed   # GNU
```

---

# 17. Shell Compatibility

Works as external binary in **Bash, Zsh, Fish, Dash**.  
**BusyBox sed** is smaller — advanced GNU features may be missing.  
Script portability issues are mostly **GNU vs BSD sed**, not shell-specific.

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Patch generated manifests in CI |
| **Embedded** | Adjust configs in rootfs build scripts |
| **Cloud** | Rewrite metadata IPs in templates |
| **Server Admin** | Quick parameter changes with backups |
| **Cybersecurity** | Redact secrets from shared logs |
| **Software Dev** | Mass update import paths |
| **Desktop** | Clean CSV exports |

---

# 19. Tips & Tricks

```bash
# Show only substituted lines
sed -n 's/foo/bar/gp' file

# Use & for whole match
sed -E 's/[0-9]+/[&]/g'

# Insert a line after match
sed '/\[Unit\]/a Description=My Service' unit.service

# Prefer file scripts for complexity
cat > fix.sed <<'EOF'
s/old/new/g
/^DEBUG/d
EOF
sed -f fix.sed app.conf
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Stream-based text transformation |
| **Most useful options** | `s///g`, `-n`, `-i.bak`, `-E`, `-e`, addresses + `d`/`p` |
| **Similar commands** | `awk`, `grep`, `perl`, `tr` |
| **Best practices** | Backup; test; avoid sed for complex structured data |
| **Common mistakes** | No `g`; bad delimiters; blind `-i` |

**Bottom line:** `sed` shines at scripted search-and-replace and line surgery — keep scripts small, backups large.
