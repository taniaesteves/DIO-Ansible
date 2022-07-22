#
# Script for parsing profiling results file from CatBpf
# Run as follow: $ python3 parse_profiling.py <path to results dir>
# The path to results dir refer to the folder containing the different types of tests.
# The script will seach for subdirectories (e.g., 'run_1', 'run_2', etc.) and parse the 'catbpf-profiling.json' file inside each subdirectory.


import sys
import os
import json
from statistics import mean
import csv
import collections


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
    runs = list_dir(path)

    # get data for each run
    for run in runs:
        run_p_file = path + "/" + run + "/catbpf-profiling.json"
        print(">>>> Parsing file '{0}'".format(run_p_file))
        data = get_json_data(run_p_file)

        for m in data["profiling_data"]:
            if not m in runs_data:
                runs_data[m] = []
            runs_data[m].append(data["profiling_data"][m])


    # replace list of values by its average
    for cur in runs_data:
        values = runs_data[cur]
        avg = str((Average(values) / 1000000))
        runs_data[cur] = avg.replace('.', ',')

    # sort dictionary
    runs_data = collections.OrderedDict(sorted(runs_data.items()))
    print(json.dumps(runs_data, indent=4, sort_keys=True))
    return runs_data

def localize_floats(row):
    return [
        str(el).replace('.', ',') if isinstance(el, float) else el
        for el in row
    ]

def main():
    if (len(sys.argv)) <= 1:
        print("Script requires the path to results folder")
        exit(1)

    args = sys.argv[1:]
    csv_file = os.path.basename(os.path.normpath(args[0])) + "_profiling.csv"
    out_dirs = list_dir(args[0])
    all_data_dic = dict()
    header = ["measure (ms)"]
    processed_dirs = 0
    for dir in out_dirs:
        print(">> Parsing profiling results for test '{0}'.".format(dir))

        try:
            data = parse(args[0]+"/"+dir)
        except EnvironmentError: # parent of IOError, OSError *and* WindowsError where available
            continue

        for key in data:
            print("key -> {0}, value -> {1}".format(key, data[key]))
            if not key in all_data_dic:
                all_data_dic[key] = [0] * processed_dirs
            print("all_data:", [all_data_dic[key]])
            all_data_dic[key].append(data[key])

        if len(data.keys()) != len(all_data_dic.keys()):
            for key in all_data_dic:
                if key not in data:
                    all_data_dic[key] = [0]
        header.append(dir)
        processed_dirs += 1

    with open(csv_file, 'w', encoding='UTF8', newline='') as f:
        writer = csv.writer(f, delimiter=";")
        writer.writerow(header)
        for row in all_data_dic:
            cur_data = [row]
            cur_data += all_data_dic[row]
            writer.writerow(localize_floats(cur_data))

    print("Parsing results saved to file '{0}'.".format(csv_file))

if __name__ == "__main__":
    main()
