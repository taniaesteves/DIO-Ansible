#
# Script for parsing profiling results file from DIO
# Run as follow: $ python3 parse_profiling.py <path to results dir>
# The path to results dir refer to the folder containing the different types of tests.
# The script will search for subdirectories (e.g., 'run_1', 'run_2', etc.) and parse the 'dio-profiling.json' file inside each subdirectory.
import sys
import os
import json
import csv
import collections
import commons

def parseSetup(path):
    runs_data = dict()
    runs = commons.ListDir(path)

    # get data for each run
    for run in runs:
        run_p_file = path + "/" + run + "/dio-profiling.json"
        print("++++++ Parsing file '{0}'".format(run_p_file))
        data = commons.GetJsonData(run_p_file)

        for m in data["profiling_data"]:
            if not m in runs_data:
                runs_data[m] = []
            runs_data[m].append(data["profiling_data"][m])

    # replace list of values by its average
    for cur in runs_data:
        values = runs_data[cur]
        avg = commons.Average(values) / 1000000
        dev = commons.STDev(values)
        runs_data[cur] = (avg, dev)

    # sort dictionary
    runs_data = collections.OrderedDict(sorted(runs_data.items()))
    return runs_data

def parseAll(input_dir):
    setup_dirs = commons.ListDir(input_dir)
    all_data_dic = dict()
    header = ["measure (ms)"]
    processed_dirs = 0

    for dir in setup_dirs:
        print("\n==> Parsing profiling results for test '{0}'.".format(dir))

        try:
            data = parseSetup(input_dir+"/"+dir)
        except EnvironmentError:
            continue

        for key in data:
            if not key in all_data_dic:
                all_data_dic[key] = [0] * processed_dirs
            all_data_dic[key].append(data[key])

        for key in all_data_dic:
            if key not in data:
                print("key '{0}' not in data".format(key))
                all_data_dic[key].append((0,0))

        header.append(dir+"-AVG")
        header.append(dir+"-DEV")
        processed_dirs += 1

    return header, all_data_dic

def storeCSV(header, data, output_file):
    with open(output_file, 'w', encoding='UTF8', newline='') as f:
        writer = csv.writer(f, delimiter=";")
        writer.writerow(header)
        for row in data:
            cur_data = [row]
            for val in data[row]:
                cur_data.append(val[0])
                cur_data.append(val[1])
            writer.writerow(commons.LocalizeFloats(cur_data))

def main():
    if (len(sys.argv)) <= 1:
        print("Script requires the path to results folder")
        exit(1)

    try:
        args = sys.argv[1:]
        input_dir = args[0]
        print("> Parsing Filebench results for folder '{0}'.".format(input_dir))

        output_file = os.path.basename(os.path.normpath(args[0])) + "_profiling.csv"

        header, data = parseAll(input_dir)
        storeCSV(header, data, output_file)
        print("\n> Results saved to file '{0}'.".format(output_file))

    except Exception as e:
        print("Error: {0}".format(e))

if __name__ == "__main__":
    main()
