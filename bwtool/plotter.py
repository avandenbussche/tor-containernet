import json
import os

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
        for idx, data in enumerate(self.data):
            self.add_subplot(data, x_max, y_max, idx)

        plt.subplots_adjust(left=0.1, right=0.85)
        ax = plt.gca()
        ax.yaxis.set_major_formatter(FuncFormatter(format_y))

        plt.show()

    def add_subplot(self, data: dict, x_max: float, y_max: float, idx: int):
        color = COLORS[idx]
        metadata = data['metadata']
        plt.axvline(metadata['ttfb'], linestyle='--', color='#dddddd')
        text_height = y_max * 0.99 - idx * (y_max / 40)
        plt.text(metadata['ttfb'] + x_max / 100, text_height, f'TTFB: {metadata["ttfb"]:.2f}s', color=color,
                 ha='left', va='top')

        plt.axvline(metadata['ttlb'], linestyle='--', color='#dddddd')
        plt.text(metadata['ttlb'] + x_max / 100, text_height, f'TTLB: {metadata["ttlb"]:.2f}s', color=color,
                 ha='left', va='top')
        x = [i['time'] for i in data['chunks']]
        y = [i['size'] for i in data['chunks']]
        plt.plot(x, y, color=color)


def read(filename: str):
    with open(filename) as in_file:
        data = json.load(in_file)
    return data


if __name__ == '__main__':
    plotter = Plotter('Download 200kB')
    dir = '200'
    files = os.listdir(dir)
    for file in files:
        path = os.path.join(dir, file)
        plotter.add_data(path)
    # plotter.add_data('1000/bwtool_1000kb_1627547571.json')
    # plotter.add_data('1000/bwtool_1000kb_1627547772.json')
    plotter.plot()
    # plot('1000/bwtool_1000kb_1627547772.json', 'Download 1000kB, QUIC, 10ms latency')
