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
    return f'{y // 1024:.0f}'


class Plotter:
    def plot(self):
        raise NotImplementedError

    def save(self, out_file: str):
        plt.savefig(out_file)


class BwPlotter(Plotter):
    def __init__(self, title: str, legend_loc='upper left'):
        self.title = title
        self.data = []
        self.legend_loc = legend_loc

    def add_data(self, filename: str):
        self.data.append(read(filename))

    def plot(self):
        plt.ylabel('Size (kB)')
        plt.xlabel('Time (s)')
        plt.grid(True)

        x_max = max(item['metadata']['ttlb'] for item in self.data)
        y_max = max(item['metadata']['size_kib'] * 1024 for item in self.data)
        lines = []
        for idx, data in enumerate(self.data):
            line, label = self.add_subplot(data, x_max, y_max, idx)
            lines.append((line, label))

        plt.legend([i[0] for i in lines], [i[1] for i in lines], framealpha=1, fancybox=False, edgecolor='white', loc=self.legend_loc)
        plt.subplots_adjust(left=0.1, right=0.85)
        ax = plt.gca()
        ax.yaxis.set_major_formatter(FuncFormatter(format_y))

    def add_subplot(self, data: dict, x_max: float, y_max: float, idx: int):
        color = COLORS[idx % len(COLORS)]
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


class AggregatePlotter(Plotter):
    field_to_name = {
        'ttlb': 'Time to Last Byte',
        'ttfb': 'Time to First Byte',
    }

    def dir_to_name(self, dirname: str):
        out = dirname.lstrip('./')
        out = out.replace('quic', 'QUIC')
        return out

    def __init__(self, title: str, field: str, legend_loc='lower right'):
        self.title = title
        self.data = {}
        self.field = field
        self.name = self.field_to_name.get(field, field)
        self.legend_loc = legend_loc

    def add_dir(self, dirname):
        files = find_in_dir(dirname)
        print("Adding", dirname)
        self.data[dirname] = [read(f) for f in files]

    def plot(self):
        plt.ylabel('Cumulative fraction')
        plt.xlabel(f'{self.name} (s)')
        plt.grid(True)

        lines = []
        for idx, name in enumerate(self.data):
            line, label = self.add_subplot(name, idx)
            lines.append((line, label))
        plt.legend([i[0] for i in lines], [i[1] for i in lines], framealpha=1, fancybox=False, edgecolor='white', loc=self.legend_loc)
        ax = plt.gca()
        ax.set_ylim(ymin=0)
        ax.set_xlim(xmin=0)

    def add_subplot(self, name: str, idx: int):
        color = COLORS[idx % len(COLORS)]
        objs = self.data[name]
        x_values = [data['metadata'][self.field] for data in objs]
        y = [i / len(objs) for i in range(len(objs))]
        label = self.dir_to_name(name)
        line, = plt.plot(sorted(x_values), y, color=color, label=label)
        return line, label


def read(filename: str):
    with open(filename) as in_file:
        data = json.load(in_file)
    return data


def find_in_dir(dirname: str):
    dir_files = os.listdir(dirname)
    return sorted([os.path.join(dirname, f) for f in dir_files if re.fullmatch(r'.*bwtool.*\.json', f)])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('file', help="File or directory to load from")
    parser.add_argument('-t', '--title', help="Title of the figure")
    parser.add_argument('-o', '--out-file', help="Output file")
    parser.add_argument('-s', '--show', default=False, help="Open output with xdg-open", action='store_true')
    parser.add_argument('-a', '--aggregate', type=str, help="Create an aggregate plot of given parameter instead")
    parser.add_argument('--legend-loc', type=str, help="Location of the legend ('best', 'upper right', 'center', ...)", default='best')
    args = parser.parse_args()

    aggregate = args.aggregate
    if not os.path.exists(args.file):
        raise RuntimeError(f"{args.file} does not exist")

    if aggregate:
        plotter = AggregatePlotter(args.title, aggregate, legend_loc=args.legend_loc)
        files = os.listdir(args.file)
        for f in files:
            path = os.path.join(args.file, f)
            if os.path.isdir(path):
                plotter.add_dir(path)
    else:
        files = []
        if os.path.isdir(args.file):
            files += find_in_dir(args.file)
        else:
            files.append(args.file)
        plotter = BwPlotter(args.title, legend_loc=args.legend_loc)
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
