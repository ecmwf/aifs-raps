# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.


rx_file_pattern = "gpu_?_pcie_rx_megabytes"
tx_file_pattern = "gpu_?_pcie_tx_megabytes"

# Find all matching files
rx_files = system(sprintf("ls %s/%s", root_dir, rx_file_pattern))
tx_files = system(sprintf("ls %s/%s", root_dir, tx_file_pattern))

# Check if any files were found
if (strlen(rx_files) == 0) {
    print "No files found matching the pattern 'gpu_?_pcie_rx_megabytes'."
    exit
}

# Define column for x-axis: 1 for unix_time, 3 for timestep
# Change this variable to switch between x-axis options
x_axis_column = 3  # Use 1 for 'unix_time', 3 for 'timestep'

# Output settings
set title "GPU PCIe usage Over Time"
set xlabel (x_axis_column == 1) ? "Unix Time" : "Step"
set ylabel "GPU PCIe (MB)"
set grid
set key outside
set terminal png size 800,600
set output 'out.png'

# Plot data
plot_command = "plot "
do for [rx_file in rx_files] {

    # Extract GPU number for the legend
    num = system(sprintf("echo %s | awk -F'/' '{print $NF}' | awk -F'_|_' '{print $2}'", rx_file))
    gpu_label = sprintf("GPU %s rx", num)

    # Append plot command for this file
    plot_command = plot_command . sprintf("'%s' using %d:2 with lines title '%s', ", rx_file, x_axis_column, gpu_label)
}
do for [tx_file in tx_files] {

    # Extract GPU number for the legend
    num = system(sprintf("echo %s | awk -F'/' '{print $NF}' | awk -F'_|_' '{print $2}'", tx_file))
    gpu_label = sprintf("GPU %s tx", num)

    # Append plot command for this file
    plot_command = plot_command . sprintf("'%s' using %d:2 with lines title '%s', ", tx_file, x_axis_column, gpu_label)
}

# Remove trailing comma and space
plot_command = substr(plot_command, 1, strlen(plot_command) - 2)

# Plot all files
eval(plot_command)