# 1. Command Name

**`journalctl`** — query the systemd journal

- **Syntax**
  ```bash
  journalctl [OPTIONS...] [MATCHES...]
  ```
- **Short Description**  
  Reads and filters logs collected by **systemd-journald**. Provides structured, centralized access to kernel messages, service logs, and boot history — often replacing traditional ad-hoc log file grepping for systemd-managed systems.

---

# 2. Purpose

## Why this command exists
systemd services commonly log to the journal instead of (or in addition to) plain files under `/var/log`. Operators need a powerful query tool with time ranges, unit filters, and follow mode.

## What problem it solves
- View logs for a specific service/unit
- Inspect previous boots after crashes
- Filter by priority, time, executable, PID
- Stream live logs while debugging

## When it should be used
- Service start failures
- Boot troubleshooting
- Security/auth event review (when journal-backed)
- Correlating multi-service incidents

🔐 Full system journal access often requires root or `systemd-journal` / `adm` group membership.

---

# 3. How it Works

## Internal working
1. journald stores log data in binary journal files (`/run/log/journal` volatile and/or `/var/log/journal` persistent).
2. `journalctl` opens those files and applies filters/matches.
3. Can export plain text, JSON, or follow like `tail -f`.
4. Uses indexed fields (`_SYSTEMD_UNIT`, `PRIORITY`, `_PID`, …) for efficient queries.

## Important concepts
| Concept | Meaning |
|---------|---------|
| **Journal** | Binary structured log storage |
| **Field matches** | `FIELD=value` filters |
| **Boot ID** | Each boot has an ID; `-b` selects boots |
| **Priority** | syslog severities (emerg…debug) |
| **Persistent logging** | Requires `/var/log/journal` configuration |
| **Pager** | Output often opens in `less` |

**Not POSIX** — systemd ecosystem tool.

---

# 4. Common Options

| Option | Meaning | Example |
|--------|---------|---------|
| `-u UNIT` | Logs for unit | `journalctl -u nginx` |
| `-f` | Follow (live) | `journalctl -fu myapp` |
| `-n N` | Show last N lines | `journalctl -n 50` |
| `-b` | Current boot | `journalctl -b` |
| `-b -1` | Previous boot | `journalctl -b -1` |
| `--list-boots` | List boot history | `journalctl --list-boots` |
| `-p PRIORITY` | Priority filter | `journalctl -p err` |
| `-S`, `--since` | Start time | `journalctl --since "2026-07-01"` |
| `-U`, `--until` | End time | `journalctl --until "1 hour ago"` |
| `-k` | Kernel messages | `journalctl -k` |
| `-e` | Jump to end in pager | `journalctl -e` |
| `-x` | Extra explanations | `journalctl -xe` |
| `-o FORMAT` | Output format | `journalctl -o json-pretty` |
| `--no-pager` | Disable pager | scripts/CI |
| `--disk-usage` | Journal size on disk | `journalctl --disk-usage` |
| `--vacuum-size=` | Shrink journal | `sudo journalctl --vacuum-size=200M` |
| `--vacuum-time=` | Remove old entries | `sudo journalctl --vacuum-time=7d` |
| `-g REGEX` | Grep message regex | `journalctl -u sshd -g failed` |
| `_PID=` | Match field | `journalctl _PID=1234` |

---

# 5. Practical Examples

## Beginner example
```bash
# All messages current boot (may be long)
journalctl -b

# Last 100 lines
journalctl -n 100 --no-pager
```

## Intermediate example
```bash
# Service logs
journalctl -u sshd --since today

# Live follow app service
journalctl -fu myapp.service

# Errors and worse this boot
journalctl -b -p err
```

## Advanced example
```bash
# Previous boot crash analysis
journalctl --list-boots
journalctl -b -1 -p warning..alert --no-pager | less

# JSON export for log pipeline testing
journalctl -u nginx --since "10 min ago" -o json | head

# Combine unit + grep
journalctl -u myapp --since "1 hour ago" -g "timeout|OutOfMemory"
```

## Real-world system administration example
```bash
# 🔐 Post-incident package: capture service failure context
sudo journalctl -u payment-api -b -p info --no-pager > /root/payment-api-boot.log
sudo journalctl -xe --no-pager | tail -n 200 >> /root/payment-api-boot.log

# Free disk when journal grows too large
sudo journalctl --disk-usage
sudo journalctl --vacuum-size=500M

# Auth-related investigation (unit names vary by distro: ssh vs sshd)
sudo journalctl -u ssh -u sshd --since "2026-07-16" -g "Failed|Invalid|Accepted"
```

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `journalctl` | Structured systemd journal queries | systemd service/boot logs |
| `dmesg` | Kernel ring buffer | Quick kernel messages |
| `tail -f /var/log/...` | Traditional files | rsyslog/file-based apps |
| `grep` on log files | Text plain text logs | Non-journal logs |
| ELK/Loki/Splunk agents | Centralized platforms | Fleet-wide observability |

**Why prefer `journalctl`?** Best native interface for unit-correlated logs and boots on systemd systems. Still use file logs when applications only write files.

---

# 7. Advantages

- **Performance:** Indexed fields; efficient time-bounded queries
- **Ease of use:** Unit-centric debugging (`-u`) is intuitive
- **Automation:** Scriptable with `--no-pager` and JSON output
- **Security:** Access controls on journal; audit-friendly structure
- **Correlation:** Boot IDs and metadata beat plain text alone

---

# 8. Disadvantages

- **Limitations:** Binary format not directly readable with `cat`
- **Risks:** Vacuuming deletes history; mis-set retention loses forensics
- **Common mistakes:** Forgetting previous boot (`-b -1`); pager confusion in scripts
- **Performance issues:** Huge persistent journals on busy hosts need retention policy

---

# 9. Exit Status

| Code | Meaning |
|------|---------|
| `0` | Success |
| `>0` | Failure (invalid options, access denied, etc.) |

Note: “no entries matched” is typically still success with empty output.

---

# 10. Common Errors

| Error / issue | Why | Fix |
|---------------|-----|-----|
| Few/no logs | Volatile journal only; service logs elsewhere | Enable persistent journal; check app config |
| `Hint: You are currently not seeing messages...` | Permission | Use `sudo` or join `systemd-journal`/`adm` |
| Pager hangs scripts | Default less | `--no-pager` |
| Missing previous boots | Retention vacuumed | Increase `SystemMaxUse` / retention |
| Wrong unit name | `ssh` vs `sshd` etc. | `systemctl list-units \| grep ssh` |

---

# 11. Best Practices

- Pair with `systemctl status UNIT` during incidents
- Use time bounds to reduce noise
- Prefer `-u` over grepping everything
- Configure persistent journals on servers that need history
- Set vacuum/size policies proactively
- Export JSON to ship to central logging when required
- Don’t blindly vacuum during active investigations

Persistent journal (concept):
```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```
(Exact steps may vary by distro policy.)

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `systemctl` | Identify failed units then inspect logs |
| `dmesg` | Kernel-focused alternative/complement |
| `logger` | Write messages into journal/syslog |
| `rsyslog`/`syslog-ng` | May forward/receive classic logs |
| `grep`/`awk` | Post-process journalctl text output |
| `timedatectl` | Ensure correct timestamps |

```bash
systemctl --failed
journalctl -u broken-service -b -n 200 --no-pager
```

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Unit logs | `journalctl -u UNIT` |
| Follow unit | `journalctl -fu UNIT` |
| Last N lines | `journalctl -n 100` |
| Current boot | `journalctl -b` |
| Previous boot | `journalctl -b -1` |
| Since time | `journalctl --since "1 hour ago"` |
| Priority err+ | `journalctl -p err` |
| Kernel | `journalctl -k` |
| No pager | `journalctl --no-pager` |
| Disk usage | `journalctl --disk-usage` |
| Vacuum size | `sudo journalctl --vacuum-size=200M` |

---

# 14. Interview Questions

## Beginner
1. How do you view logs for a systemd service?  
2. What does `journalctl -f` do?

## Intermediate
3. How do you view logs from the previous boot?  
4. Difference between journald and classic `/var/log/messages`?  
5. How do you filter by priority?

## Advanced
6. How does persistent vs volatile journaling differ?  
7. How would you export journal data for a SIEM?  
8. What retention controls exist (`SystemMaxUse`, vacuum)?

---

# 15. Exam Notes

| Exam | Focus |
|------|-------|
| **RHCSA/RHCE** | `journalctl -u`, boots, priorities, follow |
| **LPIC** | systemd logging concepts |
| **Linux+** | Basic log viewing |
| **DevOps** | Incident triage workflows |

Remember: **`systemctl status` shows a snippet; `journalctl` is for full history.**

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Options and matches |
| **DESCRIPTION** | Journal query model |
| **OPTIONS** | Filters, output formats, vacuum |
| **ENVIRONMENT** | Pager related vars |
| **SEE ALSO** | systemd-journald, journal fields |

```bash
man journalctl
man systemd.journal-fields
```

---

# 17. Shell Compatibility

Works from **Bash, Zsh, Fish, Dash** as external binary on systemd systems.  
Not applicable on pure BusyBox/OpenRC systems without journald.

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Pipeline health from service journals on runners |
| **Embedded** | systemd-based appliances debugging field issues |
| **Cloud** | Instance boot failure analysis via serial + journal |
| **Server Admin** | Daily failed unit review |
| **Cybersecurity** | Auth and sudo event harvesting |
| **Software Dev** | Local service debugging during integration |
| **Desktop** | Investigate user session service crashes |

---

# 19. Tips & Tricks

```bash
# Classic “why did my service fail?” combo
systemctl status myapp -l --no-pager
journalctl -u myapp -b -p info --no-pager | tail -n 100

# All logs for executable path
journalctl /usr/sbin/nginx

# Show UTC timestamps
journalctl -u myapp --utc

# Catalog help messages
journalctl -xe
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Query systemd journal logs |
| **Most useful options** | `-u`, `-f`, `-b`, `-n`, `--since`, `-p`, `--no-pager` |
| **Similar commands** | `dmesg`, `tail`/`grep` on files, SIEM tools |
| **Best practices** | Time-bound queries; persistent policy; pair with systemctl |
| **Common mistakes** | Missing permissions; ignoring previous boots; no retention plan |

**Bottom line:** `journalctl` is the primary log lens on systemd Linux — learn unit filters, boots, and time ranges first.
