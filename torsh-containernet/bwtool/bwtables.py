#!/usr/bin/env python3

import argparse
import json
import os
import statistics
from typing import List

from bwplotter import find_in_dir


class TableGenerator:
    def __init__(self, root_dirs: List[str], title: str, unit: str):
        self.unit = unit
        self.title = title
        self.root_dirs = root_dirs

    def run(self):
        categories = {}
        for root_dir in sorted(self.root_dirs):
            categories[root_dir] = {}
            series_dirs = os.listdir(root_dir)
            for series_dir in sorted(series_dirs):
                series_path = os.path.join(root_dir, series_dir)
                categories[root_dir][series_dir] = self.calc(series_path)
        self.plot(categories)
        print(f"\nTable: {self.title} - Average (standard deviation) of TTLB\n\n")

    def calc(self, dir: str):
        files = find_in_dir(dir)
        values = []
        for file in files:
            with open(file) as in_file:
                data = json.load(in_file)
            values.append(data['metadata']['ttlb'])
        return {
            'avg': sum(values) / len(values),
            'stddev': statistics.stdev(values)
        }

    def plot(self, categories: dict):
        headers = ['{}{}'.format(i, self.unit or '') for i in categories.keys()]
        first_row = '| {} |{}|'.format(self.title, '|'.join(headers))
        second_row = '|---|{}|'.format('|'.join(['---'] * len(categories)))
        print(first_row)
        print(second_row)
        for series in categories[list(categories.keys())[0]]:
            values = ['{:.3f}s (σ {:.3f})'.format(categories[i][series]['avg'], categories[i][series]['stddev']) for i in categories]
            line = '|{}|{}|'.format(series, '|'.join(values))
            print(line)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('dirs', nargs='+', help="Directory to load from")
    parser.add_argument('-t', '--title', help="Table title")
    parser.add_argument('-u', '--unit', help="Unit of the category")
    args = parser.parse_args()

    generator = TableGenerator(root_dirs=args.dirs, title=args.title or '', unit=args.unit)
    generator.run()
