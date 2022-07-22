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

    all_runs = dict()

    header = [ "time", "cpu_usr", "cpu_sys", "cpu_idl", "cpu_wai", "cpu_stl", "mem_used", "mem_free", "mem_buff", "mem_cach", "net_recv", "net_send", "dsk_read", "dsk_writ", "swap_used", "swap_free"]
    print(header)

    # get data for each run
    for run in runs:
        run_p_file = path + "/" + run + "/dstat.csv"
        print(">>>> Parsing file '{0}'".format(run_p_file))

        with open(run_p_file) as f:
            reader = csv.reader(f)

            r = 0
            run_values = dict()
            for row in reader:
                r+=1
                if (r>6):
                    if (len(row) < 16):
                        print(r, row)
                        continue
                    values = row

                    for index in range(len(row)-1):
                        if header[index] == "time":
                            continue

                        if not header[index] in run_values:
                            run_values[header[index]] = []
                        run_values[header[index]].append(float(row[index]))

            for cur in run_values:
                if not cur in all_runs:
                    all_runs[cur] = []
                avg = Average(run_values[cur])
                all_runs[cur].append(avg)

    # replace list of values by its average
    for cur in all_runs:
        values = all_runs[cur]
        avg = str(Average(values))
        all_runs[cur] = avg.replace('.', ',')

    # sort dictionary
    print(json.dumps(all_runs, indent=4, sort_keys=True))
    return all_runs

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
    csv_file = os.path.basename(os.path.normpath(args[0])) + "_dstat.csv"
    out_dirs = list_dir(args[0])
    all_data_dic = dict()
    header = ["param"]
    for dir in out_dirs:
        print(">> Parsing Dstat results for test '{0}'.".format(dir))

        try:
            data = parse(args[0]+"/"+dir)
        except EnvironmentError: # parent of IOError, OSError *and* WindowsError where available
            continue

        for key in data:
            if not key in all_data_dic:
                all_data_dic[key] = []
            all_data_dic[key].append(data[key])
        header.append(dir)

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
