#!/bin/bash
# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.


set -eu
output_file=$1
if [[ $1 == "" ]]; then
	echo "Error! no output file provided"
	echo "expected usage 'bash generate_json.sh /path/to/outputFile.json'"
	exit 0
fi

src_dir=$RAPS_AIFS_ROOT_DIR/build/sources/anemoi-core/models/src/anemoi/models
awk_file=$RAPS_AIFS_ROOT_DIR/etc/aifs/profiling/nsys/PythonFunctionsTrace/scripts/generate_json.awk
module_name="anemoi.models"

include_pytorch=1

rm -f $output_file

echo "[" >> $output_file
for f in $(find $src_dir -type f)
do
	awk -v module_name=$module_name -f $awk_file $f >> $output_file
done


#replace all single quotes with double quotes
# awk prefers to work with single quotes, but json needs doubles
sed -i 's/'\''/"/g' "$output_file"

#cat pytorch onto the end of the anemoi file, so we get pytorch annotations too
if [[ $include_pytorch == 1 ]]; then
pytorch_file=/perm/naco/profiling/nsys/PythonFunctionsTrace/pytorch.json
tail -n+2 $pytorch_file >> $output_file #skip first line as we are inside a list already
else
echo "]" >> $output_file
fi

#Generated code has some json syntax errors. the following steps are required to fix them:
#Open the generated file in vim and do the following subsitions
#:%s/},\n]/}\r]/g   	#remove trailing comma on last module (if not including pytorch)
