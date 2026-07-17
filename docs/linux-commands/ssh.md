# 1. Command Name

**`ssh`** — OpenSSH remote login client

- **Syntax**
  ```bash
  ssh [options] [user@]hostname [command]
  ssh [-p port] [-i identity_file] destination [command]
  ```
- **Short Description**  
  Provides encrypted remote shell access and secure command execution over an insecure network. Also forms the transport for `scp`, `sftp`, and `rsync -e ssh`.

---

# 2. Purpose

## Why this command exists
Remote administration must protect credentials and session data from eavesdropping and tampering. SSH replaced insecure protocols like Telnet and rsh.

## What problem it solves
- Interactive remote terminal sessions
- Non-interactive remote command execution
- Secure tunneling (port forwarding)
- Key-based automation without passwords

## When it should be used
- Managing Linux servers and network devices
- Git operations over SSH
- Jump hosts / bastions
- Secure file transfer companion workflows

---

# 3. How it Works

## Internal working
1. TCP connect to port 22 (default).
2. Protocol version exchange and algorithm negotiation.
3. Server host key verification against `~/.ssh/known_hosts`.
4. User authentication (public key, password, agent, etc.).
5. Opens interactive session or runs a remote command.
6. All traffic encrypted and integrity-protected.

## Important concepts
| Concept | Meaning |
|---------|---------|
| **Host key** | Server identity; first connect prompts to trust |
| **User key pair** | `id_ed25519` / `id_rsa` private+public |
| **`authorized_keys`** | Public keys allowed for a user on server |
| **ssh-agent** | Holds decrypted keys in memory |
| **ProxyJump** | Connect via bastion (`-J`) |
| **Config file** | `~/.ssh/config` host aliases and options |

**Not POSIX** — provided by OpenSSH (or Dropbear on embedded).

---

# 4. Common Options

| Option | Meaning | Example |
|--------|---------|---------|
| `-p port` | Remote port | `ssh -p 2222 user@host` |
| `-i file` | Private key file | `ssh -i ~/.ssh/prod user@host` |
| `-l user` | Login name | `ssh -l admin host` |
| `-v` / `-vv` / `-vvv` | Verbose debugging | `ssh -vv user@host` |
| `-A` | Agent forwarding (careful) | `ssh -A bastion` |
| `-X` / `-Y` | X11 forwarding | `ssh -X user@host` |
| `-L` | Local port forward | `ssh -L 8080:localhost:80 user@host` |
| `-R` | Remote port forward | `ssh -R 9000:localhost:22 user@host` |
| `-D` | Dynamic SOCKS proxy | `ssh -D 1080 user@host` |
| `-N` | No remote command (tunnels only) | `ssh -N -L ...` |
| `-f` | Background after auth | with `-N` tunnels |
| `-J host` | ProxyJump | `ssh -J bastion internal` |
| `-o Opt=Val` | Set config option | `ssh -o StrictHostKeyChecking=accept-new host` |
| `-t` | Force pseudo-tty | `ssh -t host sudo -i` |
| `-q` | Quiet | scripting |

---

# 5. Practical Examples

## Beginner example
```bash
# Login to remote server
ssh alice@192.168.1.50

# Run a single remote command
ssh alice@web01 'uptime'
```

## Intermediate example
```bash
# Specific key and port
ssh -i ~/.ssh/id_ed25519 -p 2222 deploy@prod.example.com

# Copy-free remote check
ssh web01 'df -h; free -m'
```

## Advanced example
```bash
# Jump through bastion to private host
ssh -J bastion.example.com alice@10.0.5.20

# Local forward: access remote DB on localhost:5433
ssh -N -L 5433:localhost:5432 dbuser@db.internal

# ~/.ssh/config snippet
# Host prod
#   HostName 203.0.113.10
#   User deploy
#   IdentityFile ~/.ssh/prod_ed25519
#   ProxyJump bastion
ssh prod
```

## Real-world system administration example
```bash
# 🔐 Rolling restart across app hosts
for h in app01 app02 app03; do
  ssh -o BatchMode=yes "$h" 'sudo systemctl restart myapp && systemctl is-active myapp'
done

# Restricted automation user with key-only auth
# (server side: PasswordAuthentication no, PermitRootLogin prohibit-password)
```

⚠️ Agent forwarding (`-A`) can expose your keys on compromised bastions. Prefer `ProxyJump` over agent forwarding when possible.

---

# 6. Similar Commands

| Command | Difference | When to Use |
|---------|------------|-------------|
| `ssh` | Encrypted remote shell/commands | Interactive admin + automation |
| `telnet` | Unencrypted (legacy) | Almost never on modern systems |
| `mosh` | Roaming UDP remote terminal | Unstable networks |
| `kubectl exec` | Container remote shell | Kubernetes workloads |
| `aws ssm start-session` | Cloud manager sessions | SSM-managed instances |
| `dropbear` | Lightweight SSH server/client | Embedded Linux |

**Why prefer SSH?** Industry standard encryption, keys, and tooling ecosystem. Prefer cloud session managers when organizational policy requires them.

---

# 7. Advantages

- **Performance:** Efficient multiplexed sessions (`ControlMaster`)
- **Ease of use:** Simple client; powerful config
- **Automation:** Non-interactive keys + `BatchMode`
- **Security:** Strong crypto; replaces plaintext remote admin
- **Ecosystem:** Foundation for git, rsync, Ansible, Terraform provisioners

---

# 8. Disadvantages

- **Limitations:** Requires network path and correct auth setup
- **Risks:** Stolen private keys; TOFU host key mistakes; insecure forwards
- **Common mistakes:** World-readable private keys; disabling host key checks globally
- **Performance issues:** High latency without multiplexing; large scp trees better as rsync

⚠️ Never set `StrictHostKeyChecking=no` globally in production automation without understanding MITM risk.

---

# 9. Exit Status

| Code | Meaning |
|------|---------|
| `0` | Remote command / session success |
| `255` | SSH client failure (connect/auth/error) |
| other | Exit code of remote command |

```bash
ssh host 'false'; echo $?   # 1 (remote)
ssh badhost; echo $?        # 255 (client)
```

---

# 10. Common Errors

| Error | Why | Fix |
|-------|-----|-----|
| `Connection refused` | sshd down / wrong port / firewall | Check service, port, SG/firewall |
| `Permission denied (publickey)` | Key not accepted | Install pubkey; fix modes; right user |
| `Host key verification failed` | Host key changed or MITM | Verify out-of-band; update `known_hosts` |
| `WARNING: UNPROTECTED PRIVATE KEY FILE!` | Bad key permissions | `chmod 600 ~/.ssh/id_ed25519` |
| Timeout | Network/routing/firewall | Debug with `-v`, check path |

Server key file modes matter:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/config
chmod 644 ~/.ssh/*.pub ~/.ssh/known_hosts
```

---

# 11. Best Practices

- Prefer **Ed25519** keys
- Use `~/.ssh/config` for hosts, users, jump settings
- Disable password auth on servers when keys are deployed
- Use dedicated deploy keys with least privilege
- Enable `ControlMaster` multiplexing for frequent connections
- Keep OpenSSH updated
- Log and monitor auth failures (`journalctl -u sshd`)
- For automation: `BatchMode=yes`, short `ConnectTimeout`

```sshconfig
Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519

Host bastion
  HostName bastion.example.com
  User admin

Host app-*
  ProxyJump bastion
  User deploy
```

---

# 12. Related Commands

| Command | Relationship |
|---------|--------------|
| `sshd` | Server daemon |
| `ssh-keygen` | Create keys |
| `ssh-copy-id` | Install public key on remote |
| `ssh-add` | Load keys into agent |
| `scp` / `sftp` | File transfer over SSH |
| `rsync` | Efficient sync over SSH |
| `ssh-keyscan` | Collect host keys |

```bash
ssh-keygen -t ed25519 -C "you@example.com"
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host
```

---

# 13. Cheat Sheet

| Goal | Command |
|------|---------|
| Login | `ssh user@host` |
| Remote command | `ssh user@host 'cmd'` |
| Custom port | `ssh -p 2222 user@host` |
| Identity file | `ssh -i key user@host` |
| Verbose debug | `ssh -vv user@host` |
| Jump host | `ssh -J bastion user@internal` |
| Local forward | `ssh -L 8080:localhost:80 user@host` |
| Config alias | define `Host` in `~/.ssh/config` |

---

# 14. Interview Questions

## Beginner
1. Default SSH port?  
2. How do you run a single remote command?

## Intermediate
3. How does public key authentication work?  
4. What is `known_hosts` for?  
5. Difference between `scp` and `rsync` over SSH?

## Advanced
6. Explain ProxyJump vs agent forwarding risks.  
7. How do local/remote/dynamic port forwards differ?  
8. How would you harden sshd for production?

---

# 15. Exam Notes

| Exam | Focus |
|------|-------|
| **RHCSA/RHCE** | Key-based SSH; config; firewall implications |
| **LPIC** | Client usage; keys; tunneling basics |
| **Linux+** | Remote access fundamentals |
| **DevOps** | Automation, bastions, security posture |

Know file locations: `~/.ssh/`, `/etc/ssh/sshd_config`, host key paths under `/etc/ssh/`.

---

# 16. Man Page Summary

| Section | Meaning |
|---------|---------|
| **SYNOPSIS** | Destination and command forms |
| **DESCRIPTION** | Protocol and auth overview |
| **OPTIONS** | Full client flags |
| **CONFIGURATION FILES** | `ssh_config` keywords |
| **EXIT STATUS** | 255 vs remote codes |
| **SEE ALSO** | sshd, ssh-keygen, scp |

```bash
man ssh
man ssh_config
man sshd_config
```

---

# 17. Shell Compatibility

Client works from **Bash, Zsh, Fish, Dash**.  
On **BusyBox/embedded**, you may have Dropbear (`dbclient`) instead of OpenSSH — flags differ.  
Remote login shell may be bash/zsh/sh depending on user account.

---

# 18. Real-World Use Cases

| Domain | Example |
|--------|---------|
| **DevOps** | Ansible connections over SSH |
| **Embedded** | Field device maintenance shells |
| **Cloud** | Access VMs (or hybrid with SSM/serial) |
| **Server Admin** | Daily administration of fleets |
| **Cybersecurity** | Hardened jump hosts, key audits |
| **Software Dev** | Git SSH remotes; remote devboxes |
| **Desktop** | Remote into home lab servers |

---

# 19. Tips & Tricks

```bash
# Multiplexing for speed
# ControlMaster auto
# ControlPath ~/.ssh/cm-%r@%h:%p
# ControlPersist 10m

# Escape sequences in interactive session: <Enter>~?
# Disconnect hung session: <Enter>~.

# Test config
ssh -G host | less

# Force password (debug) avoiding keys
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no user@host
```

---

# 20. Summary

| Topic | Takeaway |
|-------|----------|
| **Purpose** | Secure remote login and command execution |
| **Most useful options** | `-i`, `-p`, `-v`, `-J`, `-L/-R/-D`, `-o` |
| **Similar commands** | mosh, cloud session tools, Dropbear |
| **Best practices** | Keys not passwords; config files; least privilege |
| **Common mistakes** | Bad key perms; ignoring host key changes; insecure forwards |

**Bottom line:** SSH is the control plane of Linux remote ops — master keys, config, and jump hosts before complex tooling.
