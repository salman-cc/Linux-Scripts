# 1. Command Name

**`awk`** — pattern scanning and processing language

- **Syntax**

  ```bash
  awk [OPTION]... 'program' [file...]
  awk [OPTION]... -f progfile [file...]
  ```

- **Short Description**  
  A small programming language specialized for line-oriented, field-aware text processing. Ideal for reports, log analytics, and column manipulation.

---

# 2. Purpose

## Why this command exists

Much Unix data is structured as records (lines) and fields (columns). `awk` was designed to process that model without compiling a full program.

## What problem it solves

- Split lines into fields and print selected columns
- Filter rows by conditions
- Compute sums, averages, counts
- Format reports from command output and logs

## When it should be used

- Parsing `ps`, `df`, `netstat`/`ss`, CSV-like data
- Quick data analysis in the shell
- Writing portable text-processing one-liners
- Teaching programming concepts (patterns + actions)

---

# 3. How it Works

## Internal working

1. Optionally runs `BEGIN { ... }` before reading input.
2. For each record (default: line), splits into fields (`$1`, `$2`, … `$NF`).
3. Evaluates pattern/action rules: `pattern { action }`.
4. After EOF, runs `END { ... }`.
5. Built-in variables track NR, NF, FS, OFS, etc.

## Important concepts

| Concept | Meaning |
|---------|---------|
| **Record** | Usually one line (`RS` newline) |
| **Field** | Columns split by `FS` (default whitespace) |
| **`$0`** | Entire record |
| **`$1..$n`** | Field n |
| **`NR` / `FNR`** | Record number / per-file record number |
| **`NF`** | Number of fields |
| **`FS` / `OFS`** | Input/output field separators |
| **Pattern** | Regex `/re/`, expression, `BEGIN`/`END`, ranges |

Variants: **`awk`** (often `mawk` or `gawk` on Linux), **`gawk`** (GNU, richest features), **`nawk`**.

**POSIX vs GNU:** Core language is POSIX; `gawk` adds FPAT, networks, profiling, extra functions.

---

# 4. Common Options

| Option | Meaning | Example |
|--------|---------|---------|
| `-F fs` | Set field separator | `awk -F: '{print $1}' /etc/passwd` |
| `-f file` | Program from file | `awk -f report.awk data.csv` |
| `-v var=val` | Set variable before run | `awk -v thr=90 '$3>thr'` |
| `-O` / etc. | Implementation-specific | See `gawk` man |

## Language essentials (not CLI flags)

| Construct | Meaning | Example |
|-----------|---------|---------|
| `{print $1}` | Print first field | `awk '{print $1}' f` |
| `/regex/` | Match record | `awk '/error/ {print}' log` |
| `NR==1` | First line | `awk 'NR==1 {print}'` |
| `BEGIN{}` | Pre-input setup | `awk 'BEGIN{FS=","} {print $2}'` |
| `END{}` | Post-input | `awk '{s+=$1} END{print s}'` |
| `if/for/while` | Control flow | standard C-like syntax |
| `split()` | Split string to array | `n=split($0,a,":")` |
| `printf` | Formatted output | `awk '{printf "%-10s %s\n",$1,$2}'` |

---

# 5. Practical Examples

## Beginner example

```bash
# Print usernames from passwd
awk -F: '{print $1}' /etc/passwd

# Print column 1 and 3 of whitespace data
ps aux | awk '{print $1, $11}'
```

## Intermediate example

```bash
# Sum a numeric column
awk '{sum+=$1} END {print sum}' numbers.txt

# Filter: HTTP 500 lines and print IP + path (log-dependent)
awk '$9==500 {print $1, $7}' access.log

# Skip header then process
awk 'NR>1 && $3+0 > 80 {print $1,$3}' metrics.csv
```

## Advanced example

```bash
# Average of column 2 grouped by column 1
awk '{
  sum[$1]+=$2; cnt[$1]++
}
END {
  for (k in sum) printf "%s %.2f\n", k, sum[k]/cnt[k]
}' data.txt

# Pretty df filter for high usage (example; df format varies)
df -P | awk 'NR>1 && $5+0 > 80 {print $6, $5}'
```

## Real-world system administration example

```bash
# Top talkers from simplified access log (field positions depend on format)
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head

# Parse /etc/passwd for non-login shells inventory
awk -F: '$7 ~ /(nologin|false)$/ {print $1,$7}' /etc/passwd

# 🔐 Report SUID files from find -ls output (illustrative)
sudo find /usr -perm -4000 -type f -ls 2>/dev/null | awk '{print $3, $5, $6, $11}'
```

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `awk` | Full mini-language, fields | Reports, filters, calculations |
| `sed` | Stream edits, weaker fields | Substitutions |
| `cut` | Simple field cut | Fixed delimiter extraction only |
| `grep` | Match lines | No field math |
| `perl`/`python` | General languages | Complex multi-file apps |
| `jq` | JSON specialist | Structured JSON |

**Why prefer `awk`?** Best balance of power and brevity for columnar text. Prefer `cut` for trivial splits; `python` for maintainable large programs.

---

# 7. Advantages

- **Performance:** Fast enough for multi-hundred-MB logs
- **Ease of use:** One-liners replace dozens of lines of code
- **Automation:** Excellent in monitoring and report scripts
- **Security:** Helps analyze auth logs and access patterns quickly
- **Portability:** POSIX awk widely available

---

# 8. Disadvantages

- **Limitations:** Cryptic for large programs; arrays/features differ by implementation
- **Risks:** Silent mis-parsing if FS wrong
- **Common mistakes:** Confusing `$1` shell vs awk; quoting hell
- **Performance issues:** Very large in-memory arrays; multi-GB may need specialized tools

---

# 9. Exit Status

| Code | Meaning |
|------|---------|
| `0` | Success |
| `>0` | Syntax error, missing file, fatal runtime error |

Use explicit `exit 1` in scripts when validation fails.

---

# 10. Common Errors

| Error / issue | Why | Fix |
|---------------|-----|-----|
| Syntax error | Unbalanced braces/quotes | Put program in file; simplify quotes |
| Wrong columns | Incorrect `FS` | Set `-F` or `BEGIN{FS=...}` |
| Empty fields | Multiple delimiters | Adjust FS or preprocess |
| Shell expands `$1` | Unquoted program | Use single quotes around awk program |
| Locale number issues | Commas vs dots | Set `LC_ALL=C` when needed |

---

# 11. Best Practices

- Single-quote awk programs in shell: `awk '{print $1}'`
- Pass shell values with `-v`, not string concatenation when possible
- Prefer `gawk` features only when you control the environment
- For CSV with quotes, consider dedicated CSV tools
- Build complex logic in `.awk` files for readability
- Always validate field assumptions on sample input first

```bash
awk -v user="$USER" '$1==user {print $0}' access.db
```

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `sort` / `uniq` | Aggregate after awk extraction |
| `grep` | Pre-filter lines |
| `sed` | Pre/post text cleanup |
| `column` | Pretty-print tables |
| `paste` / `join` | Multi-file relational ops |
| `datamash` | Stats alternative |

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Print field 1 | `awk '{print $1}' f` |
| Set FS | `awk -F, '{print $2}' f` |
| Match pattern | `awk '/err/ {print}' f` |
| Sum column | `awk '{s+=$1} END{print s}' f` |
| Skip header | `awk 'NR>1 {print}' f` |
| NF fields | `awk '{print NF, $0}' f` |
| BEGIN/END | `awk 'BEGIN{print "start"} {print} END{print "done"}'` |
| Conditional | `awk '$3>100 {print $1}' f` |

---

# 14. Interview Questions

## Beginner

1. How do you print the first column with awk?  
2. What is `$0`?

## Intermediate

3. Difference between `NR` and `NF`?  
4. How do you set a custom field separator?  
5. Write an awk one-liner to sum a column.

## Advanced

6. How do associative arrays work in awk?  
7. Explain `BEGIN` and `END` blocks.  
8. POSIX awk vs gawk differences you have hit in production?

---

# 15. Exam Notes

- Field variables, `FS`, `NR`, `NF` are exam favorites
- Know `-F` and basic pattern `{action}` form
- Common pipeline: `cmd | awk ... | sort`
- LPIC covers awk more deeply than some other certs

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Program and files |
| **DESCRIPTION** | Execution model |
| **OPTIONS** | `-F`, `-f`, `-v` |
| **AWK PROGRAM** | Patterns, actions, functions |
| **VARIABLES** | Built-ins list |
| **SEE ALSO** | gawk, mawk docs |

```bash
man awk
man gawk
```

---

# 17. Shell Compatibility

External interpreter works in **Bash, Zsh, Fish, Dash**.  
**BusyBox awk** is limited; test scripts on target embedded systems.  
Quoting rules differ slightly by shell — prefer single-quoted programs.

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Parse pipeline metrics logs |
| **Embedded** | Summarize sensor CSV on device |
| **Cloud** | Process CLI inventory outputs |
| **Server Admin** | Disk/inode reports from `df` |
| **Cybersecurity** | Frequency analysis of failed logins |
| **Software Dev** | Generate code stats from tool output |
| **Desktop** | Clean and summarize exported spreadsheets |

---

# 19. Tips & Tricks

```bash
# Reformat spaces to commas
awk -v OFS=',' '{$1=$1; print}' file

# Print last field
awk '{print $NF}' file

# Multiple field separators (gawk)
gawk -F '[:\t]' '{print $1,$2}' file

# Debug fields
awk '{for(i=1;i<=NF;i++) print i,$i}' line.txt
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Field-aware text processing language |
| **Most useful options** | `-F`, `-f`, `-v`, plus `BEGIN/END`, `$n`, arrays |
| **Similar commands** | `sed`, `cut`, `perl`, `jq` |
| **Best practices** | Quote programs; use `-v`; validate FS |
| **Common mistakes** | Shell `$` expansion; wrong columns |

**Bottom line:** If your problem is “lines and columns,” start with `awk` before writing a larger script.
