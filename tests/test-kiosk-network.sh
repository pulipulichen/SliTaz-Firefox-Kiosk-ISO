#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/run"
cat > "$tmp/kiosk.conf" <<'EOF'
NETWORK_INTERFACE='eth0'
DHCP_WAIT_SECONDS=10
FALLBACK_IP='192.168.0.6'
FALLBACK_NETMASK='255.255.255.0'
FALLBACK_GATEWAY='192.168.0.1'
FALLBACK_DNS='192.168.0.1'
EOF
cat > "$tmp/network.conf" <<'EOF'
INTERFACE="eth0"
DHCP="no"
STATIC="no"
IP="192.168.0.6"
NETMASK="255.255.255.0"
GATEWAY="192.168.0.1"
DNS_SERVER="192.168.0.1"
EOF
cat > "$tmp/bin/ip" <<'EOF'
#!/bin/sh
case "$1:$2" in
  link:set) exit 0;;
  -4:addr)
    [ -f "$MOCK_RUN/dhcp" ] && echo ' inet 10.20.30.40/24 dev eth0'
    [ -f "$MOCK_RUN/static" ] && echo ' inet 192.168.0.6/24 dev eth0'
    : ;;
  -4:route)
    [ -f "$MOCK_RUN/dhcp" ] && echo 'default via 10.20.30.1 dev eth0'
    [ -f "$MOCK_RUN/static" ] && echo 'default via 192.168.0.1 dev eth0'
    : ;;
  *) exit 2;;
esac
EOF
cat > "$tmp/bin/udhcpc" <<'EOF'
#!/bin/sh
echo "$*" > "$MOCK_RUN/udhcpc.args"
[ "$MOCK_DHCP_RESULT" = success ] || exit 1
: > "$MOCK_RUN/dhcp"
EOF
printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/modprobe"
cat > "$tmp/bin/timeout" <<'EOF'
#!/bin/sh
echo "$1" > "$MOCK_RUN/timeout.seconds"
shift
"$@"
EOF
cat > "$tmp/network-service" <<'EOF'
#!/bin/sh
echo "$1" >> "$MOCK_RUN/network-service.calls"
: > "$MOCK_RUN/static"
EOF
chmod +x "$tmp/bin/"* "$tmp/network-service"
export PATH="$tmp/bin:$PATH"
export KIOSK_CONFIG_FILE="$tmp/kiosk.conf"
export KIOSK_NETWORK_CONF_FILE="$tmp/network.conf"
export KIOSK_NETWORK_SERVICE="$tmp/network-service"
export KIOSK_RUNTIME_DIR="$tmp/run"
export KIOSK_NO_CONSOLE=1
export MOCK_RUN="$tmp/run"
export MOCK_DHCP_RESULT=success
sh "$repo/scripts/kiosk-network" >/dev/null
grep -qx 'MODE=DHCP' "$tmp/run/kiosk-network.status"
grep -qx 'DHCP="yes"' "$tmp/network.conf"
grep -qx '10' "$tmp/run/timeout.seconds"
grep -q -- '-n -t 3 -T 2' "$tmp/run/udhcpc.args"
! grep -q -- '-q' "$tmp/run/udhcpc.args"
[ ! -e "$tmp/run/network-service.calls" ]
[ -f "$tmp/run/kiosk-network.ready" ]
rm -f "$tmp/run/dhcp"
export MOCK_DHCP_RESULT=failure
sh "$repo/scripts/kiosk-network" >/dev/null
grep -qx 'MODE=STATIC' "$tmp/run/kiosk-network.status"
grep -qx 'DHCP="no"' "$tmp/network.conf"
grep -qx 'STATIC="yes"' "$tmp/network.conf"
grep -qx 'IP="192.168.0.6"' "$tmp/network.conf"
grep -qx 'DNS_SERVER="192.168.0.1"' "$tmp/network.conf"
[ "$(wc -l < "$tmp/run/network-service.calls")" -eq 1 ]
[ -f "$tmp/run/kiosk-network.ready" ]
echo 'PASS: DHCP/static fallback'
