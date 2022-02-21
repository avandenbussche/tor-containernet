#!/usr/bin/env python3

import argparse
import glob
import os
import re
from collections import namedtuple

from mininet.net import Containernet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import info, setLogLevel

setLogLevel('info')
TorNode = namedtuple('TorNode', ['ip', 'path', 'nickname'])


def run(delay_ms: float, bandwidth: float, loss: float, jitter: float, docker_image='tor', add_load=False):
    info('*** Reading node data\n')
    nodes = []
    da_node_dirs = glob.glob('nodes/a*') + glob.glob('nodes/r*') + glob.glob('nodes/c*')
    for path in da_node_dirs:
        with open(os.path.join(path, 'torrc')) as in_file:
            data = in_file.read()
        ip = re.search(r'Address\s+([\d.]+)', data).group(1)
        nickname = re.search(r'Nickname\s+(\S+)', data).group(1)
        nodes.append(TorNode(ip, os.path.abspath(path), nickname))
    info("Nodes: ", '\n\t'.join([str(n) for n in nodes]), '\n')

    net = Containernet(controller=Controller)

    info('*** Adding controller\n')
    net.addController('c0')

    info('*** Adding docker containers using tor images\n')
    docker_nodes = [net.addDocker(node.nickname, ip=node.ip, dimage=docker_image, volumes=[f"{node.path}:/usr/local/etc/tor"]) for node in nodes]

    info('*** Adding switch\n')
    switch = net.addSwitch(f's0')

    # Connect nodes to their switches
    info(f'*** Adding links between nodes and the switch\n')
    delay_str = str(delay_ms) + 'ms'
    for node in docker_nodes:
        net.addLink(node, switch, cls=TCLink, delay=delay_str, bw=bandwidth, loss=loss, jitter=jitter)

    info('*** Starting network\n')
    net.start()

    info('*** Starting tor nodes\n')
    for node in docker_nodes:
        node.start()

    if add_load:
        info('*** Adding load\n')
        for node in nodes:
            if not node.nickname.startswith('c'):
                continue
            if node.nickname == 'c1':
                continue
            cmd = "while true; do bwtool.py -p 1 localhost:9050 {}:8000 -s 5000; done &".format(node.ip)
            docker_node = [n for n in docker_nodes if n.name == node.nickname][0]
            print("Running", cmd, "on", docker_node)
            docker_node.cmd(cmd)

    info('*** Running CLI\n')
    CLI(net)
    info('*** Stopping network')
    net.stop()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--delay', help='Link latency in ms', type=float, default=25)
    parser.add_argument('-l', '--loss', help='Packet loss in percentage', type=float, default=0.1)
    parser.add_argument('-b', '--bandwidth', help='Link bandwidth in Mbit/s', type=float, default=20)
    parser.add_argument('-j', '--jitter', help='Link bandwidth in ms', type=float, default=0)
    parser.add_argument('-i', '--image', help='Tor Docker image name', type=str, default='tor')
    parser.add_argument('--load', help='Continuously download through bwtool in all clients except c1', action='store_true')
    args = parser.parse_args()
    run(delay_ms=args.delay, bandwidth=args.bandwidth, loss=args.loss, jitter=args.jitter, docker_image=args.image, add_load=args.load)
