# 1. Command Name

**`grep`** — print lines that match a pattern

- **Syntax**

  ```bash
  grep [OPTION]... PATTERNS [FILE]...
  grep [OPTION]... -e PATTERNS ... [FILE]...
  grep [OPTION]... -f PATTERN_FILE [FILE]...
  ```

- **Short Description**  
  Searches input files or standard input for lines matching a regular expression (or fixed string) and prints matches. Essential for log analysis, code search, and scripting.

---

# 2. Purpose

## Why this command exists

Text is everywhere in Linux: configs, logs, source code, command output. Operators need a fast filter to extract relevant lines.

## What problem it solves

- Find lines containing a keyword or regex
- Filter command pipelines
- Recursively search project trees
- Invert match, count matches, show context

## When it should be used

- Troubleshooting logs (`journalctl`, `/var/log`)
- Searching codebases (or use `rg`/`ag` when available)
- Validating configuration content
- Building shell one-liners and CI checks

---

# 3. How it Works

## Internal working

1. Compiles the pattern (basic/extended/Perl regex engine depending on flags).
2. Reads each input line.
3. Tests the line against the pattern.
4. Emits matching lines (or filenames/counts) per options.
5. Sets exit status based on whether any match was found.

## Important concepts

| Concept | Meaning |
|---------|---------|
| **BRE** | Basic Regular Expressions (default traditional `grep`) |
| **ERE** | Extended regex (`grep -E` / `egrep`) |
| **PCRE** | Perl-compatible (`grep -P`, GNU) |
| **Fixed string** | Literal match (`-F` / `fgrep`) — faster, no regex |
| **Exit codes** | 0 match, 1 no match, 2 error — critical in scripts |
| **Binary files** | May say “Binary file matches” unless `-a`/`--binary-files` |

**POSIX vs GNU:** `grep` is POSIX; GNU grep adds `-P`, `--color`, `--exclude-dir`, recursive refinements, etc.

---

# 4. Common Options

| Option | Meaning | Example |
|--------|---------|---------|
| `-i` | Ignore case | `grep -i error app.log` |
| `-v` | Invert match (non-matching lines) | `grep -v '^#' config` |
| `-n` | Show line numbers | `grep -n TODO *.c` |
| `-r`, `-R` | Recursive directory search | `grep -r "API_KEY" .` |
| `-l` | Only filenames with matches | `grep -rl password /etc 2>/dev/null` |
| `-L` | Filenames without matches | `grep -RL enabled conf.d/` |
| `-c` | Count matching lines | `grep -c failed auth.log` |
| `-E` | Extended regex | `grep -E 'error\|fail\|fatal' log` |
| `-F` | Fixed strings (no regex) | `grep -F 'C++' notes.md` |
| `-P` | Perl regex (GNU) | `grep -P '\d{1,3}(\.\d{1,3}){3}'` |
| `-w` | Whole word match | `grep -w error log` |
| `-x` | Whole line match | `grep -x 'root' users.txt` |
| `-A N` | N lines after match | `grep -A3 'Exception' log` |
| `-B N` | N lines before match | `grep -B2 'panic' log` |
| `-C N` | N lines of context | `grep -C2 'ERROR' log` |
| `-e` | Multiple patterns | `grep -e foo -e bar file` |
| `-f` | Patterns from file | `grep -f patterns.txt data` |
| `-h` | Suppress filenames | `grep -h error *.log` |
| `-o` | Only matching part | `grep -oE '[0-9]+' file` |
| `--color=auto` | Highlight matches | `grep --color=auto error log` |
| `--exclude-dir=` | Skip directories (GNU) | `grep -r --exclude-dir=.git pattern .` |

---

# 5. Practical Examples

## Beginner example

```bash
# Find lines containing "error" in a log
grep error /var/log/syslog

# Case-insensitive
grep -i warning app.log
```

Example output:

```text
Mar 12 10:01:22 host app[2201]: error: connection refused
```

## Intermediate example

```bash
# Comments and blank lines removed from config
grep -vE '^\s*#|^\s*$' /etc/ssh/sshd_config

# Recursive search in project, skip .git
grep -rn --exclude-dir=.git "TODO" .

# Show context around failures
grep -nC3 "Failed password" /var/log/auth.log
```

## Advanced example

```bash
# Extract IPv4-like tokens (simplified)
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' access.log | sort | uniq -c | sort -nr | head

# Files that contain a secret pattern
grep -rIl --exclude-dir=node_modules 'BEGIN RSA PRIVATE KEY' .

# Pipeline: services failed then filter
systemctl --failed | grep -i failed
```

## Real-world system administration example

```bash
# 🔐 Audit sudo usage
sudo grep -i 'sudo:' /var/log/auth.log | tail -n 50

# Find which nginx vhost references a domain
sudo grep -rn "example.com" /etc/nginx --include='*.conf'

# CI-style check: fail if debug left in configs
if grep -R "DEBUG=true" /etc/myapp; then
  echo "Debug flag present" >&2
  exit 1
fi
```

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `grep` | Classic line matcher | Portable scripts, basic search |
| `egrep` | Historically `grep -E` | Legacy scripts (prefer `grep -E`) |
| `fgrep` | Historically `grep -F` | Legacy scripts (prefer `grep -F`) |
| `rg` (ripgrep) | Faster, smarter defaults | Large codebases |
| `ag` (silver searcher) | Fast code search | Development |
| `ack` | Perl-based code search | Dev workflows |
| `awk` | Full field processing language | Transform + match |
| `sed` | Edit stream by pattern | Substitution, in-place edits |

**Why prefer one over another?**  

- **`grep`**: universal and script-safe.  
- **`rg`**: interactive code search speed.  
- **`awk`/`sed`**: when matching is only part of transformation.

---

# 7. Advantages

- **Performance:** Highly optimized C implementation; good for large logs
- **Ease of use:** Simple keyword search scales to powerful regex
- **Automation:** Exit status perfect for conditionals and CI
- **Security:** Quickly hunt secrets, insecure flags, unauthorized access lines
- **Pipeline-friendly:** Core of Unix text composition

---

# 8. Disadvantages

- **Limitations:** Line-oriented; multi-line patterns are awkward without `-z`/`-P`
- **Risks:** Naïve recursive search can hit huge binary trees or network FS
- **Common mistakes:** Forgetting to quote patterns; special regex chars in fixed text
- **Performance issues:** Pathological regex can be slow; `-P` backtracking risks

⚠️ Searching `/` as root without excludes can hammer disks and expose sensitive files in terminal scrollback.

---

# 9. Exit Status

| Code | Meaning |
|------|---------|
| `0` | One or more lines selected (match found) |
| `1` | No lines selected (no match) |
| `2` | Error (invalid option, unreadable file, etc.) |

```bash
grep -q "Listen 443" /etc/apache2/ports.conf && echo "TLS port configured"
```

---

# 10. Common Errors

| Error / symptom | Why | Fix |
|-----------------|-----|-----|
| No output, exit 1 | No match | Broaden pattern; check file |
| `Invalid regular expression` | Bad regex / wrong engine | Escape metacharacters or use `-F` |
| Binary file matches | Match inside binary | Use `-I` to skip binaries or `-a` to treat as text |
| Permission denied | Unreadable files | Adjust perms / sudo / redirect stderr |
| Too many hits | Pattern too broad | Add `-w`, path limits, excludes |

---

# 11. Best Practices

- Quote patterns: `grep -E 'err|warn' file`
- Use `-F` for literal strings with special characters
- Prefer `grep -R --exclude-dir=.git` for source trees
- Use `-q` in scripts when only exit status matters
- For huge repos, consider `rg`
- Redirect stderr when scanning system dirs: `2>/dev/null` only if intentional

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `find` | Select files, then `grep` contents |
| `xargs` | Pass file lists to `grep` |
| `sed` / `awk` | Further process matched data |
| `journalctl` | Often piped to `grep` |
| `cut` / `sort` / `uniq` | Post-process matches |
| `tail -f` | Follow logs + `grep` |

```bash
find /var/log -type f -name '*.log' -print0 | xargs -0 grep -H 'OutOfMemory'
```

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Simple search | `grep pat file` |
| Ignore case | `grep -i pat file` |
| Line numbers | `grep -n pat file` |
| Invert | `grep -v pat file` |
| Recursive | `grep -rn pat dir` |
| Count | `grep -c pat file` |
| Filenames only | `grep -l pat *` |
| Extended regex | `grep -E 'a\|b' file` |
| Fixed string | `grep -F 'a+b' file` |
| Quiet (script) | `grep -q pat file` |
| Context | `grep -C2 pat file` |

---

# 14. Interview Questions

## Beginner

1. How do you search for a string in a file?  
2. What does `grep -i` do?  
3. How do you show line numbers?

## Intermediate

4. Difference between `grep`, `grep -E`, and `grep -F`?  
5. Explain exit codes 0, 1, and 2.  
6. How do you recursively search while skipping `.git`?

## Advanced

7. When would you choose PCRE (`-P`) over ERE?  
8. How do you safely match literal user input?  
9. Performance considerations on multi-GB logs?

---

# 15. Exam Notes

| Exam | Focus |
|------|-------|
| **RHCSA** | Filter logs; simple patterns; pipelines |
| **LPIC-1** | BRE vs ERE; common options; exit status |
| **Linux+** | Search files and command output |
| **DevOps** | Log triage; CI content checks |

Remember: **no match is exit 1**, not necessarily a hard failure of the tool.

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Pattern and file operands |
| **DESCRIPTION** | Matching model and regex flavors |
| **OPTIONS** | Full flag list |
| **REGULAR EXPRESSIONS** | Metacharacters and engines |
| **EXIT STATUS** | 0/1/2 semantics |
| **ENVIRONMENT** | Locale effects on matching |

```bash
man grep
```

---

# 17. Shell Compatibility

| Environment | Notes |
|-------------|-------|
| **Bash / Zsh / Fish / Dash** | External `grep` works everywhere |
| **BusyBox** | Limited `grep`; often no `-P` |

Shell quoting rules differ; always quote patterns in scripts.

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Scan deploy logs for `ERROR` |
| **Embedded** | BusyBox grep on serial console logs |
| **Cloud** | Filter cloud-init output for failures |
| **Server Admin** | Auth failure hunting in `auth.log` / `secure` |
| **Cybersecurity** | IOC string searches across disk images |
| **Software Dev** | Find all call sites of a function |
| **Desktop** | Search notes/markdown libraries |

---

# 19. Tips & Tricks

```bash
# Color + aliases
alias grep='grep --color=auto'
alias grepr='grep -rn --exclude-dir=.git --exclude-dir=node_modules'

# Match whole words only
grep -w error app.log

# Multiple patterns file
grep -f bad_ips.txt access.log

# Null data mode for weird filenames (with find -print0)
grep -Z ... # pair carefully with xargs -0

# From stdin
ss -tulpn | grep ':22'
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Find lines matching patterns in text |
| **Most useful options** | `-i`, `-n`, `-r`, `-v`, `-E`/`-F`, `-C`, `-l`, `-q` |
| **Similar commands** | `rg`, `awk`, `sed`, `ag` |
| **Best practices** | Quote patterns; use `-F` for literals; exclude heavy dirs |
| **Common mistakes** | Regex metacharacters unintended; ignoring exit code 1 |

**Bottom line:** `grep` is the universal text filter — learn `-i/-n/-r/-E/-F` and exit codes first, then context and recursion.
