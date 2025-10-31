# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

# Define input data files
file_network_recv = sprintf("%s/network_receive_megabytes", root_dir)
file_network_send = sprintf("%s/network_transmit_megabytes", root_dir)

# Define column for x-axis: 1 for unix_time, 3 for timestep
# Change this variable to switch between x-axis options
x_axis_column = 3  # Use 1 for 'unix_time', 3 for 'timestep'

# Output settings
set title "Network Activity Over Time"
set xlabel (x_axis_column == 1) ? "Unix Time" : "Step"
set ylabel "Network Traffic (MB)"
set grid
set key outside
set terminal png size 800,600
set output 'out.png'

# Plot data
plot \
    file_network_recv using x_axis_column:2 with lines title "Recv", \
    file_network_send using x_axis_column:2 with lines title "Send"