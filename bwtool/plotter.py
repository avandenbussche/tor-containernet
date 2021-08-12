import json

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter

PURPLE = '#9C27B0'
BLUE = '#2196F3'
GREEN = '#009688'

plt.rcParams["font.family"] = "Latin Modern Roman"


def format_y(y: int, pos=None):
    return f'{y // 1000:.0f}'


def plot(filename: str, title='Download over time'):
    data = read(filename)
    metadata = data['metadata']
    total_x = metadata['ttlb']

    x = [i['time'] for i in data['chunks']]
    y = [i['size'] for i in data['chunks']]

    plt.ylabel('Size (kB)')
    plt.xlabel('Time (s)')
    plt.grid(True)
    plt.axvline(metadata['ttfb'], linestyle='--', color='gray')
    plt.text(metadata['ttfb'] + total_x / 100, metadata['size_kb'] * 1000 * 0.9, f'TTFB: {metadata["ttfb"]:.2f}s', color='black')

    plt.axvline(metadata['ttlb'], linestyle='--', color='gray')
    plt.text(metadata['ttlb'] + total_x / 100, metadata['size_kb'] * 1000 * 0.9, f'TTLB: {metadata["ttlb"]:.2f}s', color='black')
    plt.title(title)

    plt.subplots_adjust(left=0.1, right=0.85)
    ax = plt.gca()
    ax.yaxis.set_major_formatter(FuncFormatter(format_y))

    plt.plot(x, y, color=BLUE)
    plt.show()


def read(filename: str):
    with open(filename) as in_file:
        data = json.load(in_file)
    return data


if __name__ == '__main__':
    plot('1000/bwtool_1000kb_1627547772.json', 'Download 1000kB, QUIC, 10ms latency')
