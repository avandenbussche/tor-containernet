#!/usr/bin/env python3

import argparse
import json
import os
import re
import subprocess
import sys

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter

BLUE = '#2196F3'
PURPLE = '#9C27B0'
GREEN = '#009688'
YELLOW = '#fdd835'
ORANGE = '#fb8c00'
RED = '#e53935'
PINK = '#d81b60'

COLORS = [BLUE, PURPLE, GREEN, YELLOW, ORANGE, RED, PINK]

plt.rcParams["font.family"] = "Latin Modern Roman"


def format_y(y: int, pos=None):
    return f'{y // 1000:.0f}'


class Plotter:
    def __init__(self, title: str):
        self.title = title
        self.data = []

    def add_data(self, filename: str):
        self.data.append(read(filename))

    def plot(self):
        plt.ylabel('Size (kB)')
        plt.xlabel('Time (s)')
        plt.grid(True)

        x_max = max(item['metadata']['ttlb'] for item in self.data)
        y_max = max(item['metadata']['size_kb'] * 1000 for item in self.data)
        lines = []
        for idx, data in enumerate(self.data):
            line, label = self.add_subplot(data, x_max, y_max, idx)
            lines.append((line, label))

        print([i[1] for i in lines])
        plt.legend([i[0] for i in lines], [i[1] for i in lines], framealpha=1, fancybox=False, edgecolor='white', loc='upper left')
        plt.subplots_adjust(left=0.1, right=0.85)
        ax = plt.gca()
        ax.yaxis.set_major_formatter(FuncFormatter(format_y))

    def add_subplot(self, data: dict, x_max: float, y_max: float, idx: int):
        color = COLORS[idx]
        metadata = data['metadata']
        self.add_vline(metadata['ttfb'], color)
        text_height = y_max + (idx + 1) * (y_max / 20)
        plt.text(metadata['ttfb'] + x_max / 100, text_height, f'{metadata["ttfb"]:.2f}s', color=color,
                 ha='center', va='bottom', fontsize=10)

        self.add_vline(metadata['ttlb'], color)
        plt.text(metadata['ttlb'] + x_max / 100, text_height, f'{metadata["ttlb"]:.2f}s', color=color,
                 ha='center', va='bottom', fontsize=10)
        x = [i['time'] for i in data['chunks']]
        y = [i['size'] for i in data['chunks']]
        label = metadata.get('name')
        if not label:
            label = 'unknown'
        line, = plt.plot(x, y, color=color, label=label)
        return line, label

    def add_vline(self, x: float, color: str):
        plt.axvline(x, color=color, linestyle='-.', linewidth=1)

    def save(self, out_file: str):
        plt.savefig(out_file)


def read(filename: str):
    with open(filename) as in_file:
        data = json.load(in_file)
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('file', help="File or directory to load from")
    parser.add_argument('-t', '--title', help="Title of the figure")
    parser.add_argument('-o', '--out-file', help="Output file")
    parser.add_argument('-s', '--show', default=False, help="Open output with xdg-open", action='store_true')
    args = parser.parse_args()

    if not os.path.exists(args.file):
        raise RuntimeError(f"{args.file} does not exist")
    files = []
    if os.path.isdir(args.file):
        dir = args.file
        dir_files = os.listdir(dir)
        for file in dir_files:
            if not re.fullmatch(r'.*bwtool.*\.json', file):
                continue
            path = os.path.join(dir, file)
            files.append(path)
    else:
        files.append(args.file)

    plotter = Plotter(args.title)
    for file in files:
        plotter.add_data(file)
    plotter.plot()
    out_file = args.out_file or '/tmp/bwplotter.svg'
    plotter.save(out_file)
    print(f"Plot saved to {out_file}")
    if args.show:
        viewer = {'linux': 'xdg-open',
                  'win32': 'explorer',
                  'darwin': 'open'}[sys.platform]
        subprocess.Popen([viewer, out_file])
