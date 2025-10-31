# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

# Define input data files
file_disk_free = sprintf("%s/disk_available_megabytes", root_dir)
file_disk_usage = sprintf("%s/disk_usage_megabytes", root_dir)

# Define column for x-axis: 1 for unix_time, 3 for timestep
# Change this variable to switch between x-axis options
x_axis_column = 3  # Use 1 for 'unix_time', 3 for 'timestep'

# Output settings
set title "Disk Usage Over Time"
set xlabel (x_axis_column == 1) ? "Unix Time" : "Step"
set ylabel "Disk Space (MB)"
set grid
set key outside
set terminal png size 800,600
set output 'out.png'

# Plot data
plot \
    file_disk_free using x_axis_column:2 with lines title "Disk available", \
    file_disk_usage using x_axis_column:2 with lines title "Disk usage"