import os
import json
from statistics import mean, stdev


def ListDir(path):
    return os.listdir(path)

def Average(lst):
    return float(round(mean(lst), 3))

def STDev(lst):
    if (len(lst) > 1):
        return float(round(stdev(lst), 3))
    else:
        return 0

def LocalizeFloats(row):
    return [
        str(el).replace('.', ',') if isinstance(el, float) else el
        for el in row
    ]

def GetJsonData(path):
    with open(path) as json_file:
        data = json.load(json_file)
    return data
