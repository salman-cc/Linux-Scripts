# 1. Command Name

**`systemctl`** — control the systemd system and service manager

- **Syntax**

  ```bash
  systemctl [OPTIONS...] COMMAND [UNIT...]
  ```

- **Short Description**  
  Primary interface to start, stop, enable, disable, restart, and inspect systemd units (services, sockets, timers, mounts, targets, etc.).

---

# 2. Purpose

## Why this command exists

Modern Linux distributions use **systemd** as init/PID 1. Administrators need a consistent tool to manage long-running services and boot behavior.

## What problem it solves

- Control service lifecycle at runtime
- Configure which units start at boot
- Inspect status, dependencies, and failures
- Isolate system states (multi-user, rescue, reboot)

## When it should be used

- Managing `nginx`, `sshd`, databases, custom apps
- Troubleshooting failed services
- Enabling services permanently
- Rebooting/poweroff via systemd

🔐 Most mutating operations require root/sudo.

---

# 3. How it Works

## Internal working

1. Talks to `systemd` via D-Bus (system or user bus).
2. Commands map to unit operations (start job, stop job, enable symlink creation, etc.).
3. Unit files from `/lib/systemd/system`, `/etc/systemd/system`, etc. define behavior.
4. `daemon-reload` re-reads unit files after edits.

## Important concepts

| Concept | Meaning |
|---------|---------|
| **Unit** | Object managed by systemd (`.service`, `.timer`, …) |
| **Service** | Long-running or oneshot process definition |
| **Enable** | Create wants/requires symlinks for boot |
| **Start** | Activate now (not necessarily enable) |
| **Target** | Grouping of units (like runlevels) |
| **Mask** | Link unit to `/dev/null` — completely block start |
| **User vs system** | `--user` for per-user systemd instance |

**Not POSIX** — systemd-specific (RHEL, Fedora, Debian, Ubuntu, Arch, etc.).

---

# 4. Common Options / Commands

| Command / option | Meaning | Example |
|------------------|---------|---------|
| `status UNIT` | Show status and recent logs | `systemctl status nginx` |
| `start UNIT` | Start now | `sudo systemctl start sshd` |
| `stop UNIT` | Stop now | `sudo systemctl stop httpd` |
| `restart UNIT` | Restart | `sudo systemctl restart myapp` |
| `reload UNIT` | Reload config if supported | `sudo systemctl reload nginx` |
| `enable UNIT` | Enable at boot | `sudo systemctl enable myapp` |
| `disable UNIT` | Disable at boot | `sudo systemctl disable myapp` |
| `enable --now` | Enable and start | `sudo systemctl enable --now myapp` |
| `is-active UNIT` | active/inactive | `systemctl is-active nginx` |
| `is-enabled UNIT` | enabled/disabled/masked | `systemctl is-enabled nginx` |
| `is-failed UNIT` | failed? | `systemctl is-failed myapp` |
| `list-units` | List loaded units | `systemctl list-units --type=service` |
| `list-unit-files` | Unit file install states | `systemctl list-unit-files` |
| `daemon-reload` | Reload unit files | `sudo systemctl daemon-reload` |
| `mask UNIT` | Prevent all start | `sudo systemctl mask bluetooth` |
| `unmask UNIT` | Undo mask | `sudo systemctl unmask bluetooth` |
| `cat UNIT` | Show unit file(s) | `systemctl cat nginx` |
| `show UNIT` | Properties | `systemctl show nginx -p FragmentPath` |
| `edit UNIT` | Drop-in override editor | `sudo systemctl edit myapp` |
| `reboot` / `poweroff` | Reboot/power off | `sudo systemctl reboot` |
| `--failed` | List failed units | `systemctl --failed` |
| `--user` | User instance | `systemctl --user status podman` |
| `-l` | Full (untruncated) output | `systemctl status -l myapp` |

---

# 5. Practical Examples

## Beginner example

```bash
# Check nginx status
systemctl status nginx

# Start and enable ssh (🔐)
sudo systemctl start sshd
sudo systemctl enable sshd
```

## Intermediate example

```bash
# Apply unit file changes after editing
sudo systemctl daemon-reload
sudo systemctl restart myapp.service

# See only failed services
systemctl --failed

# Reload web server config without full restart (if supported)
sudo systemctl reload nginx
```

## Advanced example

```bash
# Create drop-in override without editing vendor unit
sudo systemctl edit myapp.service
# opens editor for /etc/systemd/system/myapp.service.d/override.conf

# Inspect dependency tree
systemctl list-dependencies multi-user.target

# Switch to rescue target (careful)
sudo systemctl isolate rescue.target
```

## Real-world system administration example

```bash
# Deploy new service unit
sudo cp myapp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now myapp
systemctl status myapp --no-pager

# Incident response: restart and capture state
sudo systemctl restart payment-api
systemctl is-active payment-api
journalctl -u payment-api -n 100 --no-pager
```

⚠️ `systemctl isolate` changes the whole system state (can kill graphical sessions / network). Use with care on production.

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `systemctl` | systemd unit control | Modern distros with systemd |
| `service` | Legacy wrapper script | Older habits; often calls systemctl |
| `chkconfig` | SysV enable/disable (legacy) | Old RHEL SysV systems |
| `update-rc.d` | Debian SysV links (legacy) | Non-systemd legacy |
| `supervisord` | App-level process manager | App-specific process trees |
| `docker`/`podman` | Container lifecycle | Containerized workloads |

**Why prefer `systemctl`?** Native, consistent, integrates with journald, timers, dependencies, cgroups.

---

# 7. Advantages

- **Performance:** Parallel startup and dependency-aware boots
- **Ease of use:** One CLI for most service ops
- **Automation:** Idempotent enable/start patterns in config management
- **Security:** Sandboxing options in unit files (`NoNewPrivileges`, `ProtectSystem`, …)
- **Observability:** Status + journal integration

---

# 8. Disadvantages

- **Limitations:** Distro-specific; not on non-systemd systems (Alpine openrc, some embedded)
- **Risks:** Masking critical units; isolate targets; restarting databases carelessly
- **Common mistakes:** Editing units without `daemon-reload`; confusing enable vs start
- **Performance issues:** Misconfigured unit restarts loops (StartLimit*)

---

# 9. Exit Status

| Code | Meaning (typical) |
|------|-------------------|
| `0` | Success / active / enabled (for query commands that succeed) |
| `non-zero` | Failure; for `is-active`/`is-enabled` also means inactive/disabled |

```bash
systemctl is-active nginx && echo running
systemctl is-enabled nginx
```

Use carefully in scripts — read man page for each subcommand’s exit semantics.

---

# 10. Common Errors

| Error / symptom | Why | Fix |
|-----------------|-----|-----|
| `Unit not found` | Wrong name / not installed | `systemctl list-unit-files \| grep ...` |
| Changes ignored | No `daemon-reload` | Run it after unit edits |
| `Failed to start` | Exec path/perms/deps | `status` + `journalctl -xe` / `-u` |
| Disabled after reboot | Started but not enabled | `enable --now` |
| Masked unit | Linked to `/dev/null` | `unmask` then enable/start |

---

# 11. Best Practices

- Prefer **`systemctl edit`** drop-ins over editing vendor units in `/lib` or `/usr/lib`
- Always **`daemon-reload`** after unit file changes
- Use **`enable --now`** for install steps
- Check **`systemctl status`** and **`journalctl -u`** together
- Name custom units with clear prefixes
- Add restart policies thoughtfully (`Restart=on-failure`)
- Document unit dependencies in playbooks

```ini
# Example snippet /etc/systemd/system/myapp.service
[Unit]
Description=My Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/myapp
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `journalctl` | View logs for units |
| `loginctl` | User sessions |
| `hostnamectl` / `timedatectl` | Other systemd tools |
| `systemd-analyze` | Boot blame / verify |
| `ss` / `curl` | Verify service endpoints after start |
| `nginx -t` etc. | App-level config test before reload |

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Status | `systemctl status UNIT` |
| Start/stop/restart | `sudo systemctl start\|stop\|restart UNIT` |
| Enable at boot | `sudo systemctl enable UNIT` |
| Enable+start | `sudo systemctl enable --now UNIT` |
| Disable | `sudo systemctl disable UNIT` |
| Reload unit files | `sudo systemctl daemon-reload` |
| Failed units | `systemctl --failed` |
| List services | `systemctl list-units --type=service` |
| Cat unit | `systemctl cat UNIT` |
| Edit drop-in | `sudo systemctl edit UNIT` |
| Reboot | `sudo systemctl reboot` |

---

# 14. Interview Questions

## Beginner

1. How do you start a service with systemd?  
2. Difference between `start` and `enable`?

## Intermediate

3. What does `daemon-reload` do?  
4. How do you make a custom service start on boot?  
5. What is a unit file?

## Advanced

6. What does masking a service do?  
7. Explain targets vs services.  
8. How do drop-in overrides work (`systemctl edit`)?

---

# 15. Exam Notes

| Exam | Focus |
|------|-------|
| **RHCSA/RHCE** | Heavy emphasis: manage services, enable, logs |
| **LPIC** | systemd units and targets |
| **Linux+** | Service management basics |
| **DevOps** | Deploy units; health checks |

Must know: **start/stop/restart/reload/enable/disable/status/daemon-reload**.

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Commands and options |
| **DESCRIPTION** | Relationship to systemd |
| **COMMANDS** | Unit commands, unit file commands, machine commands |
| **OPTIONS** | Global flags (`--user`, `--no-pager`) |
| **EXIT STATUS** | Subcommand-specific |

```bash
man systemctl
man systemd.service
man systemd.unit
```

---

# 17. Shell Compatibility

Works in **Bash, Zsh, Fish, Dash** as external client.  
Requires **systemd** host. Not available (or not meaningful) on BusyBox/OpenRC-only systems without systemd.

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | CI deploys restart app units |
| **Embedded** | Some Yocto images use systemd for services |
| **Cloud** | cloud-init enables vendor agents |
| **Server Admin** | Day-2 operations for all daemons |
| **Cybersecurity** | Disable unused services; audit enabled units |
| **Software Dev** | Ship `.service` files with apps |
| **Desktop** | Manage user services (`--user`) for sync agents |

---

# 19. Tips & Tricks

```bash
# Follow status updates
watch -n1 'systemctl status myapp --no-pager'

# Show full environment of a service
systemctl show myapp -p Environment -p ExecStart

# Reset failed state
sudo systemctl reset-failed myapp

# List timers
systemctl list-timers --all
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Manage systemd units and system state |
| **Most useful commands** | `status`, `start/stop/restart`, `enable --now`, `daemon-reload`, `--failed` |
| **Similar commands** | legacy `service`, container runtimes |
| **Best practices** | Drop-ins; reload; pair with journalctl |
| **Common mistakes** | enable vs start; forget daemon-reload |

**Bottom line:** On modern Linux, `systemctl` is mandatory knowledge — control services carefully and verify with status + logs.
