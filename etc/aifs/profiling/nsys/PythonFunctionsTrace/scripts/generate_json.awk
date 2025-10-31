# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

BEGIN {
current_class=""
function_count=0
}

#generate module name
NR == 1 {
len=split(FILENAME,split_filename, "/")
#module_name should be passed to awk -v
module=module_name "." split_filename[len-1] "." split_filename[len]
sub(".py","",module)

#build header, looks like
#{
#        "domain": "Anemoi",
#        "colour": "0xbbd6cf",
#        "module": "anemoi.models.layers.mapper",
#        "functions": [
header="{\n" "\t'domain': 'Anemoi',\n" "\t'colour': '0xbbd6cf',\n" "\t'module': '" module "',\n" "\t'functions': ["
functions=""
}

#get all the class names
$1 == "class" {
	split($2, split_class, "(")
	class_name=split_class[1]
	current_class=class_name
	
}

#get all the function names outside of classes
$0 ~ /^def\s/ {
	split($2, split_function, "(")
	function_name=split_function[1]
	if (function_count > 0)  #add prepending comma
		functions=functions ",\n"
	functions=functions  "\t\t'" function_name "'"
	function_count+=1
}

#get all the function names inside of classes
$0 ~ /^\s+def\s/ {
	split($2, split_function, "(")
	function_name=split_function[1]
	if (function_count > 0)  #add prepending comma
		functions=functions ",\n"
	functions=functions "\t\t'" current_class "." function_name "'"
	function_count+=1

}

END {
#this is done to ensure we dont print empty modules e.g. __init__ with no functions
# I think this breaks the nsys annotations
if (function_count > 1) {
	print header
	print functions
	print "\t]"
	print "},"
}
}
