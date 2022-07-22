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
from urllib.parse import _ResultMixinBytes
from pathlib import Path


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
        run_p_file = path + "/" + run + "/filebench_output.txt"
        print(">>>> Parsing file '{0}'".format(run_p_file))
        content = []

        results_file = Path(run_p_file)
        if results_file.is_file():
            with open(run_p_file) as f:
                for ln in f:
                    if ln.__contains__("IO Summary"):
                        content = ln.split(" ")
                        print("lines -> {0}".format(ln))
                        break

            if len(content) == 0:
                print("Could not find IO Summary in file '{0}'".format(run_p_file))
                continue
        else :
            run_p_file = path + "/" + run + "/docker_logs.txt"
            with open(run_p_file) as f:
                for ln in f:
                    if ln.__contains__("IO Summary"):
                        content = ln.split(" ")
                        print("lines -> {0}".format(ln))
                        break

            if len(content) == 0:
                print("Could not find IO Summary in file '{0}'".format(run_p_file))
                continue

        run_values = dict()
        print("content -> {0}".format(content))
        run_values["operations"] = int(content[3])
        print("operations -> {0}".format(run_values["operations"]))
        run_values["operations_per_sec"] = float(content[5])
        print("operations_per_sec -> {0}".format(run_values["operations_per_sec"]))
        rd_wr = content[7].split("/")
        run_values["rd"] = int(rd_wr[0])
        run_values["wr"] = int(rd_wr[1])
        print("rd -> {0}".format(run_values["rd"]))
        print("wr -> {0}".format(run_values["wr"]))
        run_values["mb_per_sec"] = float(content[9].replace("mb/s",""))
        print("mb_per_sec -> {0}".format(run_values["mb_per_sec"]))
        run_values["ms_per_op"] = float(content[10].replace("ms/op",""))
        print("ms_per_op -> {0}".format(run_values["ms_per_op"]))

        for m in run_values:
            if not m in runs_data:
                runs_data[m] = []
            runs_data[m].append(run_values[m])

    # replace list of values by its average
    print("runs data: ", runs_data)
    for cur in runs_data:
        values = runs_data[cur]
        avg = float(round(Average(values), 3))
        runs_data[cur] = avg


    # sort dictionary
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
    csv_file = os.path.basename(os.path.normpath(args[0])) + "_filebench.csv"
    out_dirs = list_dir(args[0])
    all_data_dic = dict()
    header = ["param"]
    processed_dirs = 0
    for dir in out_dirs:
        print("\n------------------\n")
        print(">> Parsing filebench results for test '{0}'.".format(dir))

        try:
            data = parse(args[0]+"/"+dir)
        except EnvironmentError: # parent of IOError, OSError *and* WindowsError where available
            continue

        print("run_data:", data)
        for key in data:
            if not key in all_data_dic:
                all_data_dic[key] = [0] * processed_dirs
            print("key -> {0}, value -> {1}".format(key, data[key]))
            print("all_data:", all_data_dic)
            all_data_dic[key].append(data[key])

        if len(data.keys()) != len(all_data_dic.keys()):
            for key in all_data_dic:
                if key not in data:
                    all_data_dic[key] = 0
        header.append(dir)
        processed_dirs += 1

    with open(csv_file, 'w', encoding='UTF8', newline='') as f:
        writer = csv.writer(f, delimiter=';')
        writer.writerow(header)
        for row in all_data_dic:
            cur_data = [row]
            cur_data += all_data_dic[row]
            writer.writerow(localize_floats(cur_data))

    print("Parsing results saved to file '{0}'.".format(csv_file))

if __name__ == "__main__":
    main()
