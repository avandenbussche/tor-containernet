#!/bin/bash
set -e

if [[ $# != 1 ]] || { [[ "$1" != quic ]] && [[ "$1" != vanilla ]]; }
then
    echo "usage: ./create-network.sh (quic|vanilla)"
    exit 1;
fi

FLAVOR="$1"
DIR_PORT=$(grep Dirport torrc | awk '{print $2}')
DA_NODES=1
CLIENT_NODES=4
IP_TEMPLATE="10.0.0."
IP_NUMBER=5
echo "Clearing node directory"
rm -rf nodes/
mkdir nodes

TORSH_WHITELIST_AUTH_IPS=()
TORSH_WHITELIST_AUTH_PORT="8000"
TORSH_LAUNCHER_NAME="torsh-launch.sh"
TORSH_SERVER_CMD='
# Node is authority
echo "Starting TorSH server in the background"
ROCKET_ADDRESS="0.0.0.0" /torsh/bin/torsh-server --authlist-file /torsh/authlist/torsh_nodelist-0.json \
                                                 --whitelist-file /torsh/whitelist/torsh_whitelist-0.json \
                                                 --release-bin-dir /torsh/node-releases/ &'
TORSH_CLIENT_CMD='

# Node is client or relay
TOR_USER_ID=$(id -u tor)

# Redirection rules for transparent Tor
ipset create torsh-nodelist-ip-only hash:ip
ipset create torsh-dnslist-ip-only hash:ip
ipset create torsh-whitelist-ip-only hash:ip
ipset create torsh-nodelist-port-ip hash:ip,port
ipset create torsh-dnslist-port-ip hash:ip,port
ipset create torsh-whitelist-port-ip hash:ip,port

# While in OUTPUT (as opposed to PREROUTING), especially important to specify --uid-owner $TOR_USER_ID to prevent
#  infinite redirection loops with exit connections emerging from tor process
# N.B.: Sending UDP over TCP results in infinite redirection loops while both local and redirected packets
#  are handled in OUTPUT... anticipating this will go away once PREROUTING is used for local packets

# Following three rules will automatically by added by TorSH client once consensus is achieved
# iptables -t nat -A OUTPUT -p udp --dport 53 -m owner ! --uid-owner $TOR_USER_ID -j NFQUEUE --queue-num 0
# iptables -t nat -A OUTPUT -p udp --sport 9053 -m owner --uid-owner $TOR_USER_ID -j NFQUEUE --queue-num 1
# iptables -t nat -A OUTPUT -p tcp --syn --dport 9041 -m owner ! --uid-owner $TOR_USER_ID -m set --match-set torsh-nodelist-ip-only dst -j REDIRECT --to-ports 9040
# iptables -t nat -A OUTPUT -p tcp --syn -m owner ! --uid-owner $TOR_USER_ID -m set --match-set torsh-whitelist-port-ip dst,dst -j REDIRECT --to-ports 9040
# iptables -t nat -A OUTPUT -p udp -m owner ! --uid-owner $TOR_USER_ID -m set --match-set torsh-whitelist-port-ip dst,dst -j REDIRECT --to-ports 9041
# iptables -t nat -A OUTPUT -p udp -m owner ! --uid-owner $TOR_USER_ID -m set --match-set torsh-whitelist-port-ip dst,dst -j NFQUEUE --queue-num 2

# Laying the groundwork for profiling, will have to validate on device later
# iptables -t mangle -A PREROUTING -p tcp --syn -j TEE --gateway 127.0.0.2
# iptables -t mangle -A PREROUTING -p tcp --syn -j LOG --log-prefix "[tee]"
# iptables -t raw -A OUTPUT -d 127.0.0.2 -p tcp -j NFQUEUE --queue-num 3

# Create chain that will block traffic from Tor that is not in whitelist
# NOTE: There should never be any non-DNS UDP packets leaving through torsh-outgoing-filter
iptables -t mangle -N torsh-outgoing-filter
# iptables-t mangle  -A torsh-outgoing-filter -j LOG --log-prefix "[torsh all]"
iptables -t mangle -A torsh-outgoing-filter -o lo -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p tcp -s 127.0.0.1 -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p tcp -d 127.0.0.1 -j ACCEPT
# iptables -t mangle -A torsh-outgoing-filter -j LOG --log-prefix "[torsh nonlocal]"
iptables -t mangle -A torsh-outgoing-filter -p tcp -d 172.17.0.1 --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p tcp -d 172.17.0.1 -j NFQUEUE --queue-num 4
iptables -t mangle -A torsh-outgoing-filter -p tcp -m state --state NEW -m set --match-set torsh-nodelist-port-ip dst,dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p udp -m state --state NEW -m set --match-set torsh-nodelist-port-ip dst,dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p tcp -m state --state NEW -m set --match-set torsh-dnslist-port-ip dst,dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p udp -m state --state NEW -m set --match-set torsh-dnslist-port-ip dst,dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p tcp -m state --state NEW -m set --match-set torsh-whitelist-port-ip dst,dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p tcp -m state --state ESTABLISHED,RELATED -m set --match-set torsh-nodelist-ip-only dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p udp -m state --state ESTABLISHED,RELATED -m set --match-set torsh-nodelist-ip-only dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p tcp -m state --state ESTABLISHED,RELATED -m set --match-set torsh-dnslist-ip-only dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p udp -m state --state ESTABLISHED,RELATED -m set --match-set torsh-dnslist-ip-only dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -p tcp -m state --state ESTABLISHED,RELATED -m set --match-set torsh-whitelist-ip-only dst -j ACCEPT
iptables -t mangle -A torsh-outgoing-filter -j LOG --log-prefix "[torsh denied]"
iptables -t mangle -A torsh-outgoing-filter -j REJECT

# Following rule will automatically by added by TorSH client once consensus is achieved
# iptables -t mangle -A OUTPUT -m owner --uid-owner $TOR_USER_ID -j torsh-outgoing-filter

echo "Starting TorSH client in the background"
TORSH_IPTABLES_USE_OUTPUT=1 RUST_BACKTRACE=1 \
/torsh/bin/torsh-node --authlist-dir /torsh/authlist \
                      --whitelist-dir /torsh/whitelist \
                      --whitelist-update-interval 60 \
                      --relaylist-update-interval 30 \
                      --profiling-max-endpoints 10 \
                      --profiling-submission-interval 30'

TORSH_PROXY_TORRC='
# TorSH-specific configuration
# Inspired by https://gitlab.torproject.org/legacy/trac/-/wikis/doc/OpenWRT
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 9040
DNSPort 9053
ExitPolicy accept *:*'

function create_node {
  NAME=$1
  NODE_DIR=$2
  echo "Creating $NAME"
  mkdir "$NODE_DIR"
  cp torrc "$NODE_DIR/"
  if [[ "$FLAVOR" == "quic" ]]
  then
      echo "QUIC 1" >> "$NODE_DIR/torrc"
  fi
  echo "Nickname $NAME" >> "$NODE_DIR/torrc"
  IP_NUMBER=$((IP_NUMBER + 1))
  IP="${IP_TEMPLATE}${IP_NUMBER}"
  echo "Address $IP" >> "$NODE_DIR/torrc"
}

# Directory authorities
for i in $(seq $DA_NODES); do
  NAME="a$i"
  NODE_DIR="nodes/$NAME"
  create_node "$NAME" "$NODE_DIR"
  KEYPATH="$NODE_DIR/keys"
  mkdir "$KEYPATH"
  echo 'password' | tor-gencert --create-identity-key --passphrase-fd 0 -a "$IP:$DIR_PORT" \
    -i "$KEYPATH"/authority_identity_key \
    -s "$KEYPATH"/authority_signing_key \
    -c "$KEYPATH"/authority_certificate
  echo | tor -f - --list-fingerprint --datadirectory "$NODE_DIR" --orport 1 --dirserver "x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff"
  cat torrc.da >> "$NODE_DIR"/torrc
  scripts/da_fingerprint.sh "$NODE_DIR" >>nodes/da
  TORSH_WHITELIST_AUTH_IPS+=( "$IP" ) 
done
for i in $(seq $DA_NODES); do
  NAME="a$i"
  NODE_DIR="nodes/$NAME"
  cat nodes/da >> "$NODE_DIR/torrc"
  echo "ExitPolicy reject *:*" >>"$NODE_DIR/torrc"
  echo "$TORSH_SERVER_CMD" >>"$NODE_DIR/$TORSH_LAUNCHER_NAME"
done

# Client nodes
for i in $(seq $CLIENT_NODES); do
  NAME="c$i"
  NODE_DIR="nodes/$NAME"
  create_node "$NAME" "$NODE_DIR"
  cat nodes/da >> "$NODE_DIR/torrc"
  echo "SOCKSPort 9050" >> "$NODE_DIR/torrc"
  echo "$TORSH_PROXY_TORRC" >> "$NODE_DIR/torrc"
  echo "$TORSH_CLIENT_CMD" >> "$NODE_DIR/$TORSH_LAUNCHER_NAME"
done
