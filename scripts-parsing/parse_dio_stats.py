#
# Script for parsing events' statistics from DIO
# Run as follow: $ python3 parse_dio_stats.py <path to results dir>
# The path to results dir refer to the folder containing the different types of tests.
# The script will serach for subdirectories (e.g., 'run_1', 'run_2', etc.) and parse the 'dio-stats.json' file inside each subdirectory.
import sys
import os
import csv
import commons

def parseSetup(path):
    runs_data = dict()
    runs = commons.ListDir(path)

    # get data for each run
    for run in runs:
        run_p_file = path + "/" + run + "/dio-stats.json"
        print("++++++ Parsing file '{0}'".format(run_p_file))
        data = commons.GetJsonData(run_p_file)

        for m in data["tracer_stats_total"]:
            if not m in runs_data:
                runs_data[m] = []
            runs_data[m].append(data["tracer_stats_total"][m])

    # replace list of values by its average and standard deviation
    for cur in runs_data:
        values = runs_data[cur]
        avg = commons.Average(values)
        dev = commons.STDev(values)
        runs_data[cur] = (avg, dev)

    return runs_data

def parseAll(input_dir):
    setups_dir = commons.ListDir(input_dir)
    all_data_dic = dict()
    header = ["events"]
    processed_dirs = 0

    for dir in setups_dir:
        print("\n==> Parsing DIO stats results for test '{0}'.".format(dir))

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
        print("> Parsing DIO Stats for folder '{0}'.".format(input_dir))

        output_file = os.path.basename(os.path.normpath(input_dir)) + "_stats.csv"

        header, data = parseAll(input_dir)
        storeCSV(header, data, output_file)
        print("\n> Results saved to file '{0}'.".format(output_file))

    except Exception as e:
        print("Error: {0}".format(e))


if __name__ == "__main__":
    main()
