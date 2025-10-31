# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

# Pattern for GPU utilization files
file_pattern = "gpu_?_utilization_percentage"

# Find all matching files
files = system(sprintf("ls %s/%s", root_dir, file_pattern))

# Check if any files were found
if (strlen(files) == 0) {
    print "No files found matching the pattern 'gpu_?_utilization_percentage'."
    exit
}

# Define column for x-axis: 1 for unix_time, 3 for timestep
# Change this variable to switch between x-axis options
x_axis_column = 3  # Use 1 for 'unix_time', 3 for 'timestep'

# Output settings
set title "GPU Utilization Over Time"
set xlabel (x_axis_column == 1) ? "Unix Time" : "Step"
set ylabel "GPU Utilization (%)"
set grid
set key outside
set yrange [0:120]
set terminal png size 800,600
set output 'out.png'

# Plot data
plot_command = "plot "
do for [file in files] {

    # Extract GPU number for the legend
    # takes everything after the last '/' in the path => gpu_?_utilization_percentage
    # then takes the 2nd match between _
    num = system(sprintf("echo %s | awk -F'/' '{print $NF}' | awk -F'_|_' '{print $2}'", file))
    gpu_label = sprintf("GPU %s", num)

    # Append plot command for this file
    plot_command = plot_command . sprintf("'%s' using %d:2 with lines title '%s', ", file, x_axis_column, gpu_label)
}

# Remove trailing comma and space
plot_command = substr(plot_command, 1, strlen(plot_command) - 2)

# Plot all files
eval(plot_command)