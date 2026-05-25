import os
import subprocess
import platform
from pathlib import Path

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RESET = "\033[0m"


def banner():

    os.system("cls" if os.name == "nt" else "clear")

    print(YELLOW)
    print("==================================================")
    print("                    RamboEyes")
    print("              Recon Before Action")
    print("==================================================")
    print(GREEN)
    print("                 ___       ___")
    print("               /'   '\\___/'  '\\")
    print("              |                 |")
    print("              |   ( )     ( )   |")
    print("              |       ___       |")
    print("              |      (___)      |")
    print("               \\               /")
    print("                '\\___     ___/'")
    print("                     |   |")
    print("                     |   |")
    print()
    print("        EYES ON TARGET. INTEL OVER EVERYTHING.")
    print(RESET)


def ask_sudo():

    answer = input(
        f"{YELLOW}[?] Run scans with elevated privileges/sudo? (y/n): {RESET}"
    ).strip().lower()

    return answer == "y"


def create_folders(target):

    base_dir = Path.home() / "scans" / target

    raw_dir = base_dir / "00_raw_scans"
    html_dir = base_dir / "01_reports_html"
    enum_dir = base_dir / "02_enum"

    raw_dir.mkdir(parents=True, exist_ok=True)
    html_dir.mkdir(parents=True, exist_ok=True)
    enum_dir.mkdir(parents=True, exist_ok=True)

    return base_dir, raw_dir, html_dir, enum_dir


def launch_terminal(title, command):

    if os.name == "nt":

        full_command = (
            f'start "{title}" cmd /k '
            f'"color 0A && title {title} && {command}"'
        )

        subprocess.Popen(full_command, shell=True)
        return

    terminal_command = (
        "export TERM=xterm-256color; "
        "printf '\\033]11;#141D2B\\007'; "
        "printf '\\033]10;#00FF41\\007'; "
        "clear; "
        f"{command}; "
        "echo; "
        "echo '[+] Scan complete.'; "
        "echo '[+] Press ENTER to close.'; "
        "read"
    )

    if subprocess.call(
        "command -v xfce4-terminal",
        shell=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    ) == 0:

        subprocess.Popen([
            "xfce4-terminal",
            "--hold",
            "--title",
            title,
            "--command",
            f"bash -c \"{terminal_command}\""
        ])

    elif subprocess.call(
        "command -v gnome-terminal",
        shell=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    ) == 0:

        subprocess.Popen([
            "gnome-terminal",
            "--title",
            title,
            "--",
            "bash",
            "-c",
            terminal_command
        ])

    else:

        subprocess.Popen(
            f"bash -c \"{terminal_command}\"",
            shell=True
        )


def extract_ports(raw_dir):

    gnmap = raw_dir / "portScan.gnmap"

    if not gnmap.exists():
        return []

    ports = []

    with open(gnmap, "r", encoding="utf-8", errors="ignore") as f:

        for line in f:

            if "Ports:" in line:

                split_ports = line.split("Ports:")[1].split(",")

                for p in split_ports:

                    if "/open/" in p:

                        ports.append(
                            p.split("/")[0].strip()
                        )

    return ports


def tcp_full_scan(target, raw_dir, html_dir, use_sudo):

    prefix = "sudo " if use_sudo and os.name != "nt" else ""

    cmd = (
        f'{prefix}nmap -Pn -n -p- '
        f'--min-rate 5000 '
        f'-oA "{raw_dir / "portScan"}" '
        f'{target} '
        f'&& if command -v xsltproc >/dev/null 2>&1; then '
        f'xsltproc "{raw_dir / "portScan.xml"}" '
        f'-o "{html_dir / "portScan.html"}"; '
        f'fi'
    )

    print(f"{GREEN}[+] Launching TCP full scan...{RESET}")

    launch_terminal(
        "RamboEyes TCP Full Scan",
        cmd
    )


def udp_scan(target, raw_dir, html_dir, use_sudo):

    prefix = "sudo " if use_sudo and os.name != "nt" else ""

    cmd = (
        f'{prefix}nmap -Pn -sU -T4 '
        f'--top-ports 100 '
        f'--max-retries 1 '
        f'--host-timeout 3m '
        f'-oA "{raw_dir / "udpScan"}" '
        f'{target} '
        f'&& if command -v xsltproc >/dev/null 2>&1; then '
        f'xsltproc "{raw_dir / "udpScan.xml"}" '
        f'-o "{html_dir / "udpScan.html"}"; '
        f'fi'
    )

    print(f"{GREEN}[+] Launching UDP scan...{RESET}")

    launch_terminal(
        "RamboEyes UDP Scan",
        cmd
    )


def service_scan(target, raw_dir, html_dir, use_sudo):

    ports = extract_ports(raw_dir)

    if not ports:

        print(f"{RED}[-] Run TCP full scan first.{RESET}")
        return

    port_string = ",".join(ports)

    prefix = "sudo " if use_sudo and os.name != "nt" else ""

    cmd = (
        f'{prefix}nmap -Pn -n '
        f'-sC -sV '
        f'-p {port_string} '
        f'-oA "{raw_dir / "serviceScan"}" '
        f'{target} '
        f'&& if command -v xsltproc >/dev/null 2>&1; then '
        f'xsltproc "{raw_dir / "serviceScan.xml"}" '
        f'-o "{html_dir / "serviceScan.html"}"; '
        f'fi'
    )

    print(f"{GREEN}[+] Launching service scan...{RESET}")

    launch_terminal(
        "RamboEyes Service Scan",
        cmd
    )


def describe_port(port):

    mapping = {

        "21": "FTP - Tools: ftp, hydra, nmap ftp scripts.",
        "22": "SSH - Tools: ssh, ssh-audit, hydra.",
        "23": "Telnet - Tools: telnet, hydra, nc.",
        "25": "SMTP - Tools: smtp-user-enum, swaks.",
        "53": "DNS - Tools: dig, dnsenum, fierce.",
        "80": "WEB - Tools: whatweb, nikto, gobuster, ffuf.",
        "88": "Kerberos - Tools: kerbrute, impacket.",
        "111": "RPC/NFS - Tools: rpcinfo, showmount.",
        "135": "MSRPC - Tools: rpcclient, netexec.",
        "139": "SMB - Tools: smbclient, enum4linux, smbmap.",
        "389": "LDAP - Tools: ldapsearch, bloodhound-python.",
        "443": "HTTPS - Tools: whatweb, nikto, gobuster, ffuf.",
        "445": "SMB - Tools: smbclient, enum4linux, smbmap.",
        "161": "SNMP - Tools: snmpwalk, onesixtyone.",
        "2049": "NFS - Tools: showmount, rpcinfo.",
        "3306": "MySQL - Tools: mysql, hydra.",
        "3389": "RDP - Tools: xfreerdp, crowbar.",
        "5432": "PostgreSQL - Tools: psql, hydra.",
        "5985": "WinRM - Tools: evil-winrm, netexec.",
        "6379": "Redis - Tools: redis-cli.",
        "8080": "WEB - Tools: whatweb, nikto, gobuster.",
        "8443": "HTTPS - Tools: whatweb, nikto, gobuster.",
        "9200": "Elasticsearch - Tools: curl, browser.",
        "27017": "MongoDB - Tools: mongosh."
    }

    return mapping.get(
        port,
        "Unknown service - Tools: nc, curl, searchsploit."
    )


def recommendations(raw_dir):

    ports = extract_ports(raw_dir)

    if not ports:

        print(f"{RED}[-] Run TCP full scan first.{RESET}")
        return

    print()
    print(f"{CYAN}========== Recommendations =========={RESET}")

    for port in ports:

        print()
        print(f"{GREEN}[Port {port}]{RESET}")
        print(describe_port(port))


def open_reports(html_dir):

    html_files = list(html_dir.glob("*.html"))

    if not html_files:

        print(f"{RED}[-] No HTML reports found.{RESET}")
        return

    for report in html_files:

        try:

            subprocess.Popen([
                "firefox",
                str(report)
            ])

            print(
                f"{GREEN}[+] Opening {report.name} in Firefox{RESET}"
            )

        except Exception:

            print(
                f"{RED}[-] Failed to open {report}{RESET}"
            )


def menu():

    banner()

    target = input("Target IP: ").strip()

    if not target:

        print(f"{RED}[-] Target required.{RESET}")
        return

    use_sudo = ask_sudo()

    base_dir, raw_dir, html_dir, enum_dir = create_folders(target)

    print(f"{GREEN}[+] Output Directory:{RESET} {base_dir}")

    while True:

        print()
        print(f"{YELLOW}========== RamboEyes Menu =========={RESET}")
        print("1) TCP Full Scan")
        print("2) UDP Top 100 Scan")
        print("3) TCP Service Scan")
        print("4) Recommendations")
        print("5) Open HTML Reports")
        print("0) Exit")
        print()

        choice = input("Choose option: ").strip()

        if choice == "1":

            tcp_full_scan(
                target,
                raw_dir,
                html_dir,
                use_sudo
            )

        elif choice == "2":

            udp_scan(
                target,
                raw_dir,
                html_dir,
                use_sudo
            )

        elif choice == "3":

            service_scan(
                target,
                raw_dir,
                html_dir,
                use_sudo
            )

        elif choice == "4":

            recommendations(raw_dir)

        elif choice == "5":

            open_reports(html_dir)

        elif choice == "0":

            print(f"{GREEN}[+] Exiting RamboEyes.{RESET}")
            break

        else:

            print(f"{RED}[-] Invalid option.{RESET}")


if __name__ == "__main__":
    menu()
