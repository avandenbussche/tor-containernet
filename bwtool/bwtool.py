#!/usr/bin/env python3

import argparse
import json
import os.path
import subprocess
import time
from subprocess import Popen
from typing import Optional

import requests


class BwTool:
    def __init__(self, address: str, port: int, size: int, proxy: str):
        self.address = address
        self.proxy = proxy
        self.port = port
        self.size = size
        self.server_process = None  # type: Optional[Popen]
        self.data = {}

    def run(self):
        try:
            self._create_file()
            self.start_server()
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
        metadata = self.data.setdefault('metadata', {})
        metadata['size_kb'] = self.size
        metadata['address'] = self.address
        metadata['proxy'] = self.proxy
        metadata['port'] = self.port
        start = time.time()
        metadata['start'] = start
        proxies = {
            'http': f'socks5://{self.proxy}',
            'htts': f'socks5://{self.proxy}',
        } if self.proxy else None
        response = requests.get(f'http://{self.address}:{self.port}/file.bin', proxies=proxies, stream=True)
        print(f"Received response, status={response.status_code}")
        now = time.time()
        metadata['ttfb'] = now - start
        chunks = self.data.setdefault('chunks', [])
        chunks.append({
            'size': 0,
            'time': now - start
        })
        total = 0
        last_print = time.time()
        for chunk in response.iter_content(10_000):
            now = time.time()
            total += len(chunk)
            if now - last_print > 0.1:
                last_print = now
                print(f'\r{total // 1000:>10}/{self.size}kB', end='', flush=True)
            chunks.append({
                'size': total,
                'time': now - start
            })
        print()
        metadata['ttlb'] = time.time() - start
        metadata['end'] = time.time()

    def save_data(self):
        name = f'bwtool_{self.size}kb_{int(time.time())}.json'
        with open(name, 'w') as out_file:
            json.dump(self.data, out_file)
        print(f"Saved data to {os.path.abspath(name)}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--address', type=str, default='0.0.0.0', help='IP address to download from')
    parser.add_argument('-p', '--port', type=int, default=8000)
    parser.add_argument('-s', '--size', type=int, help='Size in kB', default=1000)
    parser.add_argument('-x', '--proxy', type=str, help='host:port combination for the SOCKS proxy to be used (e.g. "10.0.0.7:8000")')
    args = parser.parse_args()

    bwtool = BwTool(args.address, args.port, args.size, args.proxy)
    bwtool.run()
