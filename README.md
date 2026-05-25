# RamboEyes

<p align="center">
Recon Before Action
</p>

<p align="center">
  <img src="screenshots/menu.png" width="450">
</p>

RamboEyes is a Bash-based reconnaissance helper for HTB/CPTS-style labs.

---

## Features

- **TCP Full Port Scan**
  - Performs a fast full-range TCP scan across all 65535 ports using Nmap.

- **Fast UDP Top 100 Scan**
  - Scans the top 100 UDP ports using optimized timing and retry settings to reduce scan time.

- **TCP Service Scan**
  - Performs service/version detection and default NSE script enumeration against discovered TCP ports.

- **Web Enumeration**
  - Automatically detects web ports and launches:
    - WhatWeb
    - Nikto
    - Gobuster

- **SMB Enumeration**
  - Performs SMB share, user, and OS enumeration using:
    - smbclient
    - enum4linux
    - Nmap SMB NSE scripts

- **NFS/RPC Enumeration**
  - Detects and enumerates RPC/NFS services using:
    - rpcinfo
    - showmount

- **HTML Report Generation**
  - Converts Nmap XML results into readable HTML reports using xsltproc.

- **Port-Based Recommendations**
  - Provides recommendations for discovered ports, including likely services and useful tools for enumeration.

- **Separate Themed Terminals**
  - Launches scans in separate terminal windows with custom terminal colors for easier multitasking and visibility.

---

## Requirements

Most tools used by RamboEyes are included by default in Kali Linux.

Required tools:

- nmap
- xsltproc
- firefox
- xfce4-terminal or gnome-terminal
- whatweb
- nikto
- gobuster
- smbclient
- enum4linux

---

## Usage

```bash
chmod +x ramboeyes.sh
./ramboeyes.sh
```

---

## Folder Structure

```text
scans/
└── TARGET_IP/
    ├── 00_raw_scans/
    ├── 01_reports_html/
    ├── 02_enum/
    └── notes.md
```

---

## Screenshot

<p align="center">
  <img src="screenshots/menu.png" width="450">
</p>

---

## Disclaimer

RamboEyes is intended for educational purposes, authorized security testing, and lab environments only.

The author does not encourage, condone, or authorize the use of this tool against systems, networks, or applications without explicit written permission from the owner.

Users are solely responsible for ensuring their activities comply with all applicable local, state, federal, and international laws and regulations.

By using this software, you acknowledge and agree that:

- You are responsible for your own actions and conduct.
- You will use this tool only in environments where you have authorization to do so.
- The author assumes no liability and is not responsible for any misuse, damage, data loss, service disruption, legal consequences, or other impacts resulting from the use or misuse of this software.

This project is provided "as is" without warranty of any kind, express or implied.
