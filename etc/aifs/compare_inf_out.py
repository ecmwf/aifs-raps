# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

import pygrib
import numpy as np

import argparse
parser = argparse.ArgumentParser()

default_param="U component of wind"
default_level=850

parser.add_argument("file1", help="path to first inference output grib file")
parser.add_argument("file2", help="path to second inference output grib file")
parser.add_argument("--param", "-p", nargs='?', default=default_param, help="The parameter to be compared e.g. 'U component of wind'")
parser.add_argument("--level", "-l", nargs='?', default=default_level, type=int, help="The level to be compared e.g. '850'")
parser.add_argument("--list", action='store_true', help="Print possible parameters for comparison present in both files")

args = parser.parse_args()

def list_parameters(file):
    params=[]
    with pygrib.open(file) as grbs:
        for grb in grbs:
            params.append(grb.name)
    params=list(set(params)) #get unique elements only
    return params

def get_possible_parameters(file1, file2):
    params1 = list_parameters(file1)
    params2 = list_parameters(file2)
    shared = list(set(params1).intersection(params2))
    return shared

# Function to extract the parameter at a specific level
def get_parameter(file, param_name, level):
    with pygrib.open(file) as grbs:
        for grb in grbs:
            #print(f"{grb.name=}")
            if grb.name == param_name and grb.level == level:
                return grb.values
        raise ValueError(f"{param_name} at level {level} not found in {file}")

def compare_params(file1, file2, param_name, level):

    v1 = get_parameter(file1, param_name, level)
    v2 = get_parameter(file2, param_name, level)

    if np.array_equal(v1, v2):
        print(f"{param_name} at level {level} is equal in both files.")
    else:
        print(f"{param_name} at level {level} is not equal in both files.")
        diffs=mv.integrate( abs((v2-v1)/(v1 + 1.e-20)) )
        print(f"Median difference: {np.median(diffs)}" ) 


if __name__ == "__main__":
    if args.list:
        shared = get_possible_parameters(args.file1, args.file2)
        print(f"Parameters shared between '{args.file1}' and '{args.file2}' are \n{shared}")
        exit()

    print(f"Comparing '{args.param}' (level {args.level}) across '{args.file1}' and '{args.file2}'")
    compare_params(args.file1, args.file2, args.param, args.level)
