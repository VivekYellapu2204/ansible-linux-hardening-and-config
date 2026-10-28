# Enterprise Linux OS Hardening & Lifecycle Management (Ansible)

A production-grade, modular Ansible framework designed for Center for Internet Security (CIS) Benchmark Level 1 & Level 2 hardening, baseline system standardization, and automated lifecycle verification across enterprise Linux fleets (RHEL, Rocky Linux, Amazon Linux 2023, Ubuntu Server).

---

## 1. Architectural Architecture & Operational Lifecycle

This repository functions as the central automation engine for system-level configuration management. It is designed to operate in two core modes:
1. **Upstream Image Baking:** Executed non-interactively by HashiCorp Packer to bake immutable, hardened Golden AMIs.
2. **Runtime Configuration Enforcement:** Executed against running fleet nodes to remediate configuration drift, conduct kernel tuning, apply monthly security patches, and perform post-rehydration smoke tests.

## 2. Hardening Controls & Implemented Standards

The configuration roles in this repository map directly to **CIS Benchmark Controls**:

### Identity, Access & SSH (`security_ssh`)
* **Prohibit Root Access:** `PermitRootLogin no` enforces non-privileged logins with explicit privilege escalation (`sudo`).
* **Cryptographic Authentication:** Disables `PasswordAuthentication` entirely, requiring verified SSH key pairs.
* **Session Governance:** `ClientAliveInterval 300` and `ClientAliveCountMax 0` drop inactive terminal sessions after 5 minutes of inactivity.
* **Brute-Force Mitigation:** `MaxAuthTries 3` drops connection attempts after 3 consecutive failures.

### Kernel Network Stack Hardening (`security_sysctl`)
* **Anti-Spoofing & Routing:** Deactivates IP forwarding (`net.ipv4.ip_forward = 0`) and sets reverse-path filtering (`rp_filter = 1`).
* **Denial of Service Shielding:** Enables TCP SYN cookies (`net.ipv4.tcp_syncookies = 1`) and ignores ICMP broadcast requests.
* **Memory Protection:** Configures complete Address Space Layout Randomization (`kernel.randomize_va_space = 2`).

### Integrity Auditing (`security_auditd`)
* **Identity Tracking:** Persistent auditing tracking writes/attributes to `/etc/passwd`, `/etc/shadow`, `/etc/group`, and `/etc/gshadow`.
* **Privilege Escalation:** Monitors modifications across `/etc/sudoers` and `/etc/sudoers.d/`.
* **Immutability Enforcement:** Sets `-e 2` to lock audit rule updates until the next system reboot.

### OS Baseline & Storage Minimization (`os_baseline`)
* **Legacy Filesystems:** Completely removes and blacklists unnecessary filesystem drivers (`cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`, `squashfs`, `udf`).
* **Time Synchronization:** Binds `chronyd` exclusively to local hypervisor and enterprise NTP time services.
* **Default Umask:** Sets organizational default `umask 027` across all interactive login shells.

---

3. Operational Runbook & Execution

1. Dry-Run & Drift Analysis (Check Mode)
Execute without altering state to identify configuration drift:
```bash
ansible-playbook -i inventories/dynamic-aws-ec2.yml playbooks/site.yml --check --diff
2. Full Fleet Hardening & Baseline EnforcementExecute the complete set of roles across all dynamic inventory targets:Bashansible-playbook -i inventories/dynamic-aws-ec2.yml playbooks/site.yml
3. Targeted Role Execution via TagsWhen executing targeted maintenance windows, use Ansible tags:Bash# Execute only SSH daemon updates
ansible-playbook -i inventories/dynamic-aws-ec2.yml playbooks/site.yml --tags "ssh"

# Execute only kernel network tuning
ansible-playbook -i inventories/dynamic-aws-ec2.yml playbooks/site.yml --tags "sysctl"

# Execute only baseline package and NTP sync
ansible-playbook -i inventories/dynamic-aws-ec2.yml playbooks/site.yml --tags "baseline"
4. Rolling Patching & Reboot WorkflowRun rolling package upgrades across instances in serial batches ($20\%$ of fleet at a time):Bashansible-playbook -i inventories/dynamic-aws-ec2.yml playbooks/routine-patching.yml
5. Post-Rehydration Smoke & Compliance VerificationVerify that newly rehydrated compute instances satisfy compliance and operational baselines:Bashansible-playbook -i inventories/dynamic-aws-ec2.yml playbooks/post-rehydration-verify.yml
Alternatively, run the automated compliance shell script:Bashchmod +x scripts/run-compliance-audit.sh
./scripts/run-compliance-audit.sh inventories/dynamic-aws-ec2.yml
