#
# Script for parsing profiling results file from CatBpf
# Run as follow: $ python3 parse_profiling.py <path to results dir>
# The path to results dir refer to the folder containing the different types of tests.
# The script will seach for subdirectories (e.g., 'run_1', 'run_2', etc.) and parse the 'catbpf-profiling.json' file inside each subdirectory.


from doctest import run_docstring_examples
import sys
import os
import json
from statistics import mean
import csv
import collections
from urllib.parse import _ResultMixinBytes
import math
from datetime import datetime


def list_dir(path):
    return os.listdir(path)


def get_json_data(profiling_file):
    with open(profiling_file) as json_file:
        data = json.load(json_file)
    return data

def Average(lst):
    return mean(lst)

def parse(path):
    runs_data = dict()

    with open(path) as file:
        for line in file:
            # print(line.rstrip())
            data = line.split("  ",4)
            # print(data[1], data[2], data[3])
            second = math.ceil(int(data[1]) / 1000000000)
            # print("seconds is: ", math.ceil(int(data[1]) / 1000000000))
            if data[0] not in runs_data:
                runs_data[data[0]] = dict()

            if second not in runs_data[data[0]]:
                runs_data[data[0]][second] = (0,0)
            cur_d = runs_data[data[0]][second]
            runs_data[data[0]][second] = (cur_d[0] + int(data[2]), cur_d[1] + int(data[3]))

    for str in runs_data:
        print(str)
        with open(str+".dat", 'w', encoding='UTF8', newline='') as f:
            for sec in runs_data[str]:
                # print(sec, runs_data[data[0]][sec][0], runs_data[data[0]][sec][1])
                dt_object = datetime.fromtimestamp(sec)
                f.write("\"{0}\"\t{1}\n".format(dt_object, int(runs_data[str][sec][1])/1024))


def main():
    if (len(sys.argv)) <= 1:
        print("Script requires the path to results folder")
        exit(1)

    parse(sys.argv[1])
    # args = sys.argv[1:]
    # csv_file = os.path.basename(os.path.normpath(args[0])) + "_stats.csv"
    # out_dirs = list_dir(args[0])
    # all_data_dic = dict()
    # header = ["events"]
    # processed_dirs = 0
    # for dir in out_dirs:
    #     print(">> Parsing stats results for test '{0}'.".format(dir))

    #     try:
    #         data = parse(args[0]+"/"+dir)
    #     except EnvironmentError: # parent of IOError, OSError *and* WindowsError where available
    #         continue

    #     for key in data:
    #         if not key in all_data_dic:
    #             all_data_dic[key] = [0] * processed_dirs
    #         all_data_dic[key].append(data[key])

    #     if len(data.keys()) != len(all_data_dic.keys()):
    #         for key in all_data_dic:
    #             if key not in data:
    #                 all_data_dic[key] = 0
    #     header.append(dir)
    #     processed_dirs += 1

    # with open(csv_file, 'w', encoding='UTF8', newline='') as f:
    #     writer = csv.writer(f)
    #     writer.writerow(header)
    #     for row in all_data_dic:
    #         cur_data = [row]
    #         cur_data += all_data_dic[row]
    #         writer.writerow(cur_data)

    # print("Parsing results saved to file '{0}'.".format(csv_file))

if __name__ == "__main__":
    main()