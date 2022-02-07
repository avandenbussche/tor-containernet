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
RELAY_NODES=0 # NOTE: TorSH should not have idea of relay nodes, since all clients are also relays!
CLIENT_NODES=3
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
ROCKET_ADDRESS="0.0.0.0" /torsh/bin/torsh-server --authlist-file /torsh/authlist/torsh_nodelist-0.json --whitelist-file /torsh/whitelist/torsh_whitelist-0.json &'
TORSH_CLIENT_CMD='
# Node is client or relay
# Redirection rules for transparent Tor
ipset create torsh-nodelist hash:ip
ipset create torsh-whitelist hash:ip,port
iptables -t nat -A OUTPUT -p udp --dport 53 -m set --match-set torsh-whitelist dst,dst -j REDIRECT --to-ports 9053
iptables -t nat -A OUTPUT -p tcp --syn -m set --match-set torsh-whitelist dst,dst -j REDIRECT --to-ports 9040
# Block traffic from Tor that is not in whitelist
TOR_USER_ID=$(id -u tor)
#iptables -t filter -A OUTPUT -p tcp -m state --state NEW -m owner --uid-owner $TOR_USER_ID -m set ! --match-set torsh-authlist dst -j DROP
#iptables -t filter -A OUTPUT -p tcp -m state --state NEW -m owner --uid-owner $TOR_USER_ID -j REJECT
iptables -N torsh-outgoing-filter
#iptables -A torsh-outgoing-filter -j LOG --log-prefix "[torsh all]"
iptables -A torsh-outgoing-filter -p tcp -m set --match-set torsh-nodelist dst -j ACCEPT
iptables -A torsh-outgoing-filter -p udp -m set --match-set torsh-nodelist dst -j ACCEPT
iptables -A torsh-outgoing-filter -p tcp -m set --match-set torsh-whitelist dst,dst -j ACCEPT
#iptables -A torsh-outgoing-filter -j LOG --log-prefix "[torsh denied]"
iptables -A torsh-outgoing-filter -j REJECT
# Following rule will automatically by added by TorSH client once consensus is achieved
# iptables -t filter -A OUTPUT -m owner --uid-owner $TOR_USER_ID -j torsh-outgoing-filter
echo "Starting TorSH client in the background"
/torsh/bin/torsh-node --authlist-dir /torsh/authlist --whitelist-dir /torsh/whitelist --update-interval 60 '
TORSH_PROXY_TORRC='
# TorSH-specific configuration
# Inspired by https://gitlab.torproject.org/legacy/trac/-/wikis/doc/OpenWRT
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 9040
DNSPort 9053'

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
  cat nodes/da >>"$NODE_DIR/torrc"
  echo "$TORSH_SERVER_CMD" >>"$NODE_DIR/$TORSH_LAUNCHER_NAME"
done

# Relay nodes
# NOTE: TorSH should not have idea of relay nodes, since all clients are also relays!
for i in $(seq $RELAY_NODES); do
  NAME="r$i"
  NODE_DIR="nodes/$NAME"
  create_node "$NAME" "$NODE_DIR"
  cat nodes/da >> "$NODE_DIR/torrc"
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
