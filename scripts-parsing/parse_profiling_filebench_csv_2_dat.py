import sys
import csv
import pprint


def parseCSV(path):
    data = dict()
    cur_param = ""
    reader = csv.DictReader(open(path), delimiter=';')
    stor_list = []
    while True:
        try:
            dictobj = next(reader)

            for key in dictobj:
                if (key == 'param'):
                    cur_param = dictobj[key]
                    if (cur_param not in data):
                        data[cur_param] = {}
                    continue

                if "1ES" in key:
                    stor = "elk"
                    setup = key.replace("dio_1ES_profiling_","")
                elif "file" in key:
                    stor = "file"
                    setup = key.replace("dio_file_profiling_","")
                elif "null" in key:
                    stor = "null"
                    setup = key.replace("dio_null_profiling_","")
                else:
                    stor = "unknown"
                    setup = key
                    print("unknown storage type:", key)

                if stor not in stor_list:
                    stor_list.append(stor)

                if ("AVG" in setup):
                    setup = setup.replace("-AVG","")
                    VAL = "AVG"
                if ("DEV" in setup):
                    setup = setup.replace("-DEV","")
                    VAL = "DEV"

                if setup not in data[cur_param]:
                    data[cur_param][setup] = {}
                if stor not in data[cur_param][setup]:
                    data[cur_param][setup][stor] = {}
                data[cur_param][setup][stor][VAL] = dictobj[key]
        except StopIteration:
            break
    return stor_list, data

def storeDAT(stor_list, data, path):
    header = "{0};"
    for stor in stor_list:
        header += stor + ";" + stor + "-DEV;"

    with open(path, 'w',  newline='') as f:
        for key in data:
            print(header.format(key).replace("_", "\\\\\\_"), file=f)
            for setup in sorted(data[key]):
                line = "{0};".format(setup)
                for stor in stor_list:
                    line += "{0}; {1};".format(data[key][setup][stor]["AVG"], data[key][setup][stor]["DEV"])
                print(line.replace(",",".").replace("_", "\\\\\\_"), file=f)
            print("\n", file=f)

def main():
    if (len(sys.argv)) <= 1:
        print("Script requires the path to results folder")
        exit(1)

    try:
        input_file = sys.argv[1]
        output_file = input_file + ".dat"

        print("> Parsing CSV file '{0}'.\n".format(input_file))
        stor_list, data = parseCSV(input_file)
        pprint.pprint(data)
        storeDAT(stor_list, data, output_file)
        print("\n> Results saved to file '{0}'.".format(output_file))

    except Exception as e:
        print("ERROR: {0}".format(e))

if __name__ == "__main__":
    main()
