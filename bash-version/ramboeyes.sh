#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${YELLOW}"
echo "=================================================="
echo "                    RamboEyes"
echo "              Recon Before Action"
echo "=================================================="
echo -e "${GREEN}"
echo "                 ___       ___"
echo "               /'   '\\___/'  '\\"
echo "              |                 |"
echo "              |   ( )     ( )   |"
echo "              |       ___       |"
echo "              |      (___)      |"
echo "               \\               /"
echo "                '\\___     ___/'"
echo "                     |   |"
echo "                     |   |"
echo
echo "        EYES ON TARGET. INTEL OVER EVERYTHING."
echo -e "${NC}"

ask_yes_no() {

    read -p "$1 (y/n): " ANSWER

    [[ "$ANSWER" =~ ^[Yy]$ ]]
}

describe_port() {

    case $1 in

        20|21)
            echo "FTP - File transfer. Check anonymous login, uploads, writable folders."
            echo "Tools: ftp, hydra, nmap ftp scripts."
            ;;

        22)
            echo "SSH - Remote shell. Check version, keys, weak creds."
            echo "Tools: ssh, ssh-audit, hydra."
            ;;

        23)
            echo "Telnet - Plaintext shell."
            echo "Tools: telnet, hydra, nc."
            ;;

        25|465|587)
            echo "SMTP - Mail service."
            echo "Tools: smtp-user-enum, swaks."
            ;;

        53)
            echo "DNS - Name service."
            echo "Tools: dig, dnsenum, fierce."
            ;;

        69)
            echo "TFTP - Weak/simple file transfer."
            echo "Tools: tftp, atftp."
            ;;

        80|81|443|3000|5000|5001|7001|8000|8008|8080|8081|8088|8443|8888|9000|9090|10000)
            echo "WEB - Web application/API/admin portal."
            echo "Tools: whatweb, nikto, gobuster, ffuf, curl."
            ;;

        88)
            echo "Kerberos - Active Directory authentication."
            echo "Tools: kerbrute, impacket."
            ;;

        110|995)
            echo "POP3 - Mail retrieval."
            echo "Tools: hydra, openssl."
            ;;

        111)
            echo "RPCBind - RPC mapper."
            echo "Tools: rpcinfo, showmount."
            ;;

        135)
            echo "MSRPC - Windows RPC mapper."
            echo "Tools: rpcclient, netexec."
            ;;

        139|445)
            echo "SMB - Windows file sharing/authentication."
            echo "Tools: smbclient, enum4linux, smbmap, netexec."
            ;;

        143|993)
            echo "IMAP - Mail access."
            echo "Tools: hydra, openssl."
            ;;

        161|162)
            echo "SNMP - Network management."
            echo "Tools: snmpwalk, onesixtyone, snmp-check."
            ;;

        389|636)
            echo "LDAP - Directory service."
            echo "Tools: ldapsearch, bloodhound-python."
            ;;

        2049)
            echo "NFS - Network file sharing."
            echo "Tools: showmount, mount."
            ;;

        3306)
            echo "MySQL - Database."
            echo "Tools: mysql, hydra."
            ;;

        3389)
            echo "RDP - Remote desktop."
            echo "Tools: xfreerdp, crowbar."
            ;;

        5432)
            echo "PostgreSQL - Database."
            echo "Tools: psql, hydra."
            ;;

        5985|5986|47001)
            echo "WinRM - Remote PowerShell."
            echo "Tools: evil-winrm, netexec."
            ;;

        6379)
            echo "Redis - Database."
            echo "Tools: redis-cli."
            ;;

        8009)
            echo "AJP/Tomcat connector."
            echo "Tools: ajpy."
            ;;

        9200|9300)
            echo "Elasticsearch."
            echo "Tools: curl, browser."
            ;;

        27017)
            echo "MongoDB."
            echo "Tools: mongosh."
            ;;

        *)
            echo "Unknown/uncommon service."
            echo "Tools: nc, curl, searchsploit, nmap NSE."
            ;;
    esac
}

read -p "Target IP: " TARGET

if ask_yes_no "Run with sudo"; then

    SUDO="sudo -n"

    echo -e "${YELLOW}[+] Authenticating sudo once...${NC}"

    sudo -v || exit 1

    while true; do

        sudo -n true
        sleep 60
        kill -0 "$$" || exit

    done 2>/dev/null &

else

    SUDO=""

fi

BASE_DIR="$HOME/scans/$TARGET"

RAW_DIR="$BASE_DIR/00_raw_scans"
HTML_DIR="$BASE_DIR/01_reports_html"
ENUM_DIR="$BASE_DIR/02_enum"

mkdir -p "$RAW_DIR"
mkdir -p "$HTML_DIR"
mkdir -p "$ENUM_DIR"

cd "$BASE_DIR" || exit

run_in_terminal() {

    TITLE="$1"
    SCRIPT="$2"

    if command -v xfce4-terminal >/dev/null 2>&1; then

        xfce4-terminal \
        --title="$TITLE" \
        --hold \
        --disable-server \
        --hide-menubar \
        --hide-toolbar \
        --hide-scrollbar \
        --font="Monospace 11" \
        --command="bash '$SCRIPT'" &

    elif command -v gnome-terminal >/dev/null 2>&1; then

        gnome-terminal --title="$TITLE" -- bash "$SCRIPT" &

    else

        bash "$SCRIPT" &

    fi
}

make_script() {

    NAME="$1"
    BODY="$2"

    FILE="$BASE_DIR/.ramboeyes_${NAME}.sh"

    cat > "$FILE" <<EOF
#!/bin/bash

export TERM=xterm-256color

printf '\033]11;#141D2B\007'
printf '\033]10;#00FF41\007'

clear

$BODY

echo
echo "[+] Scan complete."
echo "[+] Review results above."
echo "[+] Press ENTER to close window."

read
EOF

    chmod +x "$FILE"

    echo "$FILE"
}

tcp_full_scan_cmd='

cd "'"$BASE_DIR"'"

echo "[+] RamboEyes TCP full scan started"

'"$SUDO"' nmap \
-Pn \
-n \
-p- \
--min-rate 5000 \
-oA "'"$RAW_DIR"'/portScan" \
"'"$TARGET"'"

PORTS=$(awk "/^[0-9]+\/tcp/ && /open/ {split(\$1,a,\"/\"); print a[1]}" "'"$RAW_DIR"'/portScan.nmap" | paste -sd, -)

echo "$PORTS" > "'"$BASE_DIR"'/openPorts.txt"

echo "[+] TCP full scan complete"
echo "[+] Open ports: $PORTS"

if command -v xsltproc >/dev/null 2>&1; then

    xsltproc "'"$RAW_DIR"'/portScan.xml" -o "'"$HTML_DIR"'/portScan.html" 2>/dev/null

fi
'

udp_scan_cmd='

cd "'"$BASE_DIR"'"

echo "[+] RamboEyes UDP top 100 scan started"

echo "[+] Fast UDP mode enabled"

'"$SUDO"' nmap \
-Pn \
-sU \
-T4 \
--top-ports 100 \
--max-retries 1 \
--host-timeout 3m \
-oA "'"$RAW_DIR"'/udpScan" \
"'"$TARGET"'"

echo "[+] UDP scan complete"

if command -v xsltproc >/dev/null 2>&1; then

    xsltproc "'"$RAW_DIR"'/udpScan.xml" -o "'"$HTML_DIR"'/udpScan.html" 2>/dev/null

fi

if grep -q "161/udp.*open" "'"$RAW_DIR"'/udpScan.nmap" 2>/dev/null; then

    echo "[+] SNMP detected"

    if command -v snmpwalk >/dev/null 2>&1; then

        snmpwalk -v2c -c public "'"$TARGET"'" | tee "'"$ENUM_DIR"'/snmpwalk_public.txt"

    fi
fi
'

tcp_service_scan_cmd='

cd "'"$BASE_DIR"'"

if [ ! -f openPorts.txt ]; then

    echo "[-] openPorts.txt not found. Run TCP full scan first."
    exit

fi

PORTS=$(cat openPorts.txt)

if [ -z "$PORTS" ]; then

    echo "[-] No open TCP ports found."
    exit

fi

echo "[+] TCP service scan started on: $PORTS"

'"$SUDO"' nmap \
-Pn \
-n \
-p "$PORTS" \
-sC \
-sV \
-oA "'"$RAW_DIR"'/serviceScan" \
"'"$TARGET"'"

echo "[+] TCP service scan complete"

if command -v xsltproc >/dev/null 2>&1; then

    xsltproc "'"$RAW_DIR"'/serviceScan.xml" -o "'"$HTML_DIR"'/serviceScan.html" 2>/dev/null

fi
'

web_enum_cmd='

cd "'"$BASE_DIR"'"

if [ ! -f openPorts.txt ]; then

    echo "[-] openPorts.txt not found. Run TCP full scan first."
    exit

fi

PORTS=$(cat openPorts.txt)

FOUND=0

for PORT in $(echo "$PORTS" | tr "," " "); do

    case $PORT in

        80|81|443|3000|5000|5001|7001|8000|8008|8080|8081|8088|8443|8888|9000|9090|10000)

            FOUND=1

            if [ "$PORT" = "443" ] || [ "$PORT" = "8443" ]; then

                URL="https://'"$TARGET"':$PORT"

            else

                URL="http://'"$TARGET"':$PORT"

            fi

            echo "[+] Web enum: $URL"

            if command -v whatweb >/dev/null 2>&1; then

                whatweb "$URL" | tee "'"$ENUM_DIR"'/whatweb_$PORT.txt"

            fi

            if command -v nikto >/dev/null 2>&1; then

                nikto -h "$URL" | tee "'"$ENUM_DIR"'/nikto_$PORT.txt"

            fi

            if command -v gobuster >/dev/null 2>&1; then

                gobuster dir \
                -u "$URL" \
                -w /usr/share/wordlists/dirb/common.txt \
                -o "'"$ENUM_DIR"'/gobuster_$PORT.txt"

            fi
            ;;
    esac
done

if [ "$FOUND" = "0" ]; then

    echo "[-] No web ports found."

fi
'

smb_enum_cmd='

cd "'"$BASE_DIR"'"

if [ ! -f openPorts.txt ]; then

    echo "[-] openPorts.txt not found."
    exit

fi

PORTS=$(cat openPorts.txt)

if echo "$PORTS" | tr "," "\n" | grep -Eq "^(139|445)$"; then

    echo "[+] SMB detected"

    if command -v smbclient >/dev/null 2>&1; then

        smbclient -L "//'"$TARGET"'" -N | tee "'"$ENUM_DIR"'/smbclient.txt"

    fi

    if command -v enum4linux >/dev/null 2>&1; then

        enum4linux "'"$TARGET"'" | tee "'"$ENUM_DIR"'/enum4linux.txt"

    fi

    '"$SUDO"' nmap \
    -Pn \
    -n \
    -p445 \
    --script smb-enum-shares,smb-enum-users,smb-os-discovery,smb2-security-mode \
    -oA "'"$ENUM_DIR"'/smb_nse" \
    "'"$TARGET"'"

else

    echo "[-] SMB ports not found."

fi
'

nfs_enum_cmd='

cd "'"$BASE_DIR"'"

if [ ! -f openPorts.txt ]; then

    echo "[-] openPorts.txt not found."
    exit

fi

PORTS=$(cat openPorts.txt)

if echo "$PORTS" | tr "," "\n" | grep -Eq "^(111|2049)$"; then

    echo "[+] RPC/NFS detected"

    if command -v rpcinfo >/dev/null 2>&1; then

        rpcinfo -p "'"$TARGET"'" | tee "'"$ENUM_DIR"'/rpcinfo.txt"

    fi

    if command -v showmount >/dev/null 2>&1; then

        showmount -e "'"$TARGET"'" | tee "'"$ENUM_DIR"'/showmount.txt"

    fi

else

    echo "[-] RPC/NFS ports not found."

fi
'

show_recommendations() {

    echo
    echo -e "${CYAN}========== RamboEyes Recommendations ==========${NC}"

    if [[ ! -f "$BASE_DIR/openPorts.txt" ]]; then

        echo -e "${YELLOW}[!] No openPorts.txt yet. Run TCP full scan first.${NC}"
        return

    fi

    PORTS=$(cat "$BASE_DIR/openPorts.txt")

    if [[ -z "$PORTS" ]]; then

        echo -e "${RED}[-] No open TCP ports found.${NC}"
        return

    fi

    for PORT in $(echo "$PORTS" | tr "," " "); do

        echo
        echo -e "${GREEN}[Port $PORT]${NC}"

        describe_port "$PORT"

    done
}

open_reports() {

    if command -v firefox >/dev/null 2>&1; then

        find "$HTML_DIR" -name "*.html" -type f -exec firefox {} + >/dev/null 2>&1 &

        echo -e "${GREEN}[+] Opening reports in Firefox${NC}"

    else

        echo -e "${RED}[-] Firefox not found${NC}"

    fi
}

create_notes() {

    PORTS=""

    [[ -f "$BASE_DIR/openPorts.txt" ]] && PORTS=$(cat "$BASE_DIR/openPorts.txt")

    cat > "$BASE_DIR/notes.md" <<EOF
# RamboEyes Recon Notes

Target: $TARGET

Open TCP Ports:
$PORTS

Folders:
- 00_raw_scans
- 01_reports_html
- 02_enum

UDP Scan:
nmap -Pn -sU -T4 --top-ports 100 --max-retries 1 --host-timeout 3m
EOF

    echo -e "${GREEN}[+] notes.md created${NC}"
}

while true; do

    echo
    echo -e "${YELLOW}========== RamboEyes Menu ==========${NC}"

    echo "1) Launch TCP full scan"
    echo "2) Launch UDP top 100 scan"
    echo "3) Launch TCP service scan"
    echo "4) Show recommendations"
    echo "5) Launch web enum"
    echo "6) Launch SMB enum"
    echo "7) Launch NFS/RPC enum"
    echo "8) Create notes.md"
    echo "9) Open reports with Firefox"
    echo "0) Exit"

    echo

    read -p "Choose option: " CHOICE

    case "$CHOICE" in

        1)

            run_in_terminal \
            "RamboEyes TCP Full - $TARGET" \
            "$(make_script tcpfull "$tcp_full_scan_cmd")"
            ;;

        2)

            run_in_terminal \
            "RamboEyes UDP - $TARGET" \
            "$(make_script udp "$udp_scan_cmd")"
            ;;

        3)

            run_in_terminal \
            "RamboEyes TCP Service - $TARGET" \
            "$(make_script tcpservice "$tcp_service_scan_cmd")"
            ;;

        4)

            show_recommendations
            ;;

        5)

            run_in_terminal \
            "RamboEyes Web Enum - $TARGET" \
            "$(make_script webenum "$web_enum_cmd")"
            ;;

        6)

            run_in_terminal \
            "RamboEyes SMB Enum - $TARGET" \
            "$(make_script smbenum "$smb_enum_cmd")"
            ;;

        7)

            run_in_terminal \
            "RamboEyes NFS Enum - $TARGET" \
            "$(make_script nfsenum "$nfs_enum_cmd")"
            ;;

        8)

            create_notes
            ;;

        9)

            open_reports
            ;;

        0)

            echo -e "${GREEN}[+] Exiting RamboEyes${NC}"
            exit 0
            ;;

        *)

            echo -e "${RED}[-] Invalid option${NC}"
            ;;
    esac
done
