#!/usr/bin/env python3

import argparse
import json
import os.path
import subprocess
import time
from socket import socket
from subprocess import Popen
from typing import Optional
from urllib.parse import urlparse

from python_socks.sync import Proxy


class BwTool:
    def __init__(self, address: str, port: int, proxy_address: str, proxy_port: int, size: int, chunk_size: int,
                 print_interval: float, name: str):
        self.print_interval = print_interval
        self.proxy_port = proxy_port
        self.proxy_address = proxy_address
        self.address = address
        self.port = port
        self.size = size
        self.chunk_size = chunk_size
        self.name = name
        self.server_process = None  # type: Optional[Popen]
        self.data = {}

    def run(self):
        try:
            self._create_file()
            self.start_server()
            self.init_data()
            self.do_request()
            self.save_data()
        finally:
            if self.server_process:
                print("Shutting down...")
                self.server_process.kill()

    def _create_file(self):
        with open('file.bin', 'wb') as out_file:
            contents = b'0' * 1000 * self.size
            out_file.write(contents)

    def start_server(self):
        self.server_process = subprocess.Popen(['python3', '-m', 'http.server', '--bind', '0.0.0.0', str(self.port)])
        time.sleep(1)

    def do_request(self):
        print(f"Downloading {self.size}kB"
              f" from http://{self.address}:{self.port}"
              f" over socks5://{self.proxy_address}:{self.proxy_port}")
        metadata = self.data['metadata']
        chunks = self.data['chunks']

        start = time.time()
        metadata['start'] = start

        sock = self.connect()
        metadata['connected'] = time.time() - start

        sock.recv(1)
        ttfb = time.time() - start
        metadata['ttfb'] = ttfb
        chunks.append({
            'size': 1,
            'time': ttfb
        })
        total = 1
        last_print = time.time()
        last_chunk = chunks[0]
        while True:
            data = sock.recv(self.chunk_size)
            if not data:
                break
            now = time.time()
            total += len(data)
            chunk = {
                'size': total,
                'time': now - start
            }
            chunks.append(chunk)

            if now - last_print > self.print_interval:
                total_diff = chunk['size'] - last_chunk['size']
                time_diff = chunk['time'] - last_chunk['time']
                speed = (total_diff / time_diff) // 1000
                print(f'\r{total // 1000:>10}/{self.size}kB {speed}kB/s', ' ' * 4, end='', flush=True)
                last_print = now
                last_chunk = chunk
        print()
        metadata['ttlb'] = time.time() - start
        metadata['end'] = time.time()

    def init_data(self):
        metadata = self.data.setdefault('metadata', {})
        metadata['size_kb'] = self.size
        metadata['proxy_port'] = self.proxy_port
        metadata['proxy_address'] = self.proxy_address
        metadata['address'] = self.address
        metadata['port'] = self.port
        metadata['name'] = self.name
        self.data['chunks'] = [{
            'time': 0,
            'size': 0
        }]

    def connect(self) -> socket:
        proxy = Proxy.from_url(f'socks5://{self.proxy_address}:{self.proxy_port}')
        sock = proxy.connect(dest_host=self.address, dest_port=self.port)
        request = (
            'GET /file.bin HTTP/1.1\r\n'
            f'Host: {self.address}\r\n'
            'Connection: close\r\n\r\n'
        ).encode()
        sock.sendall(request)
        return sock

    def save_data(self):
        filename = f'bwtool_{self.size}kb_{int(time.time())}.json'
        if self.name:
            filename = f'{self.name}_{filename}'
        with open(filename, 'w') as out_file:
            json.dump(self.data, out_file)
        print(f"Saved data to {os.path.abspath(filename)}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('proxy', type=str, help='address:port of the SOCKS proxy to use')
    parser.add_argument('address', type=str, help='Target address:port combination')
    parser.add_argument('-s', '--size', type=int, help='Size in kB', default=1000)
    parser.add_argument('-c', '--chunk-size', type=int, help='Chunk size in B', default=1024)
    parser.add_argument('-p', '--print-interval', type=float, help='Print interval in seconds', default=1)
    parser.add_argument('-n', '--name', type=str, help='Name to prepend to the filename')
    args = parser.parse_args()
    proxy = urlparse(f'//{args.proxy}')
    address = urlparse(f'//{args.address}')
    size = args.size

    bwtool = BwTool(address=address.hostname, port=address.port or 80, proxy_address=proxy.hostname, proxy_port=proxy.port or 8000,
                    size=size, chunk_size=args.chunk_size, print_interval=args.print_interval, name=args.name)
    bwtool.run()
