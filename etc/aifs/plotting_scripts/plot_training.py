# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

import matplotlib.pyplot as plt
import pandas as pd
import argparse

plt.style.use('seaborn-v0_8-pastel')
wedgeprops = {"edgecolor" : "black",'linewidth': 1,}

def convert_to_ms(time_str):
    # Strip any whitespace
    time_str = time_str.strip()
    
    # Extract the numeric part and the unit
    # Find the position where the unit starts
    for i, char in enumerate(time_str):
        if not (char.isdigit() or char == '.' or char == '-'):
            numeric_part = time_str[:i]
            unit = time_str[i:]
            break
    else:
        # If no unit found, assume it's already in ms
        return float(time_str)
    
    # Convert the numeric part to float
    value = float(numeric_part)
    
    # Convert to milliseconds based on the unit
    if unit == 'us' or unit == 'µs':  # microseconds
        return value / 1000
    elif unit == 'ms':  # already in milliseconds
        return value
    elif unit == 's':  # seconds
        return value * 1000
    elif unit == 'min':  # minutes
        return value * 60 * 1000
    elif unit == 'h' or unit == 'hr':  # hours
        return value * 60 * 60 * 1000
    else:
        raise ValueError(f"Unsupported time unit: {unit}")
    
def sum_cuda_time(df):
        # Ensure the column exists and handle missing values
        if "Self CUDA" not in df.columns or df.empty:
            return 0
        return df["Self CUDA"].apply(convert_to_ms).sum()

def filter_anemoi_names(df):
    # Define the substrings we want to match
    target_substrings = ["anemoi-encoder", "anemoi-decoder", "anemoi-processor"]
    
    # Create a mask that is True for rows where the Names column contains any of the target substrings
    mask = df['Name'].str.contains('|'.join(target_substrings), case=True)
    
    # Apply the mask to filter the DataFrame
    filtered_df = df[mask]
    
    return filtered_df

def gpu_only(df):
    return df[df["Self CUDA"] != "0.000us"]

#returns 'Memcpy HtoD (Pinned -> Device) ' 'Memcpy DtoD (Device -> Device)'
def get_memcpy_results(df):
    #print(df[["Name"]])
    #need the space after 'Memcpy' otherwise we match 'cudaMemcpyAsync'
    filter= df[df["Name"].str.contains("Memcpy ", case=False)]
    #print(filter[["Name", "# of Calls","Self CUDA"]])
    return filter

def get_compute_results(df):
    df = df[df["Self CUDA"] != "0.000us"]
    #need the space after 'Memcpy' otherwise we match 'cudaMemcpyAsync'
    filter= df[df["Name"].str.contains("void", case=False)]
    #print(filter[["Name", "# of Calls","Self CUDA"]])
    return filter

def get_aten_results(df):
    df = df[df["Self CUDA"] != "0.000us"]
    #need the space after 'Memcpy' otherwise we match 'cudaMemcpyAsync'
    filter= df[df["Name"].str.contains("aten::", case=False)]
    #print(filter[["Name", "# of Calls","Self CUDA"]])
    return filter

#returns "nccl:allreduce", etc
def get_nccl_results(df):
    df = df[df["Self CUDA"] != "0.000us"]
    #need the space after 'Memcpy' otherwise we match 'cudaMemcpyAsync'
    #filter= df[df["Name"].str.contains("nccl:", case=False)]
    filter= df[df["Name"].str.contains("ncclD", case=False)]
    #print(filter[["Name", "# of Calls","Self CUDA"]])
    return filter

def plot_compute(df, outdir, per_elem=False, bar=False, top_N=0, aten=False):
    if aten:
        df=get_aten_results(df)
    else:
        df=get_compute_results(df)
    
    # Convert times to ms
    df["Time_ms"] = df["Self CUDA"].apply(convert_to_ms)
    
    # Apply per element calculation if needed
    if per_elem:
        df["Time_ms"] = df["Time_ms"] / df["# of Calls"]
    
    # Sort by time in descending order
    df_sorted = df.sort_values(by="Time_ms", ascending=False).reset_index(drop=True)
    
    # Handle the top N and "other" aggregation if N > 0
    if top_N > 0 and len(df_sorted) > top_N:
        # Get the top N rows
        top_n = df_sorted.iloc[:top_N]
        
        # Calculate the sum of times for the rest
        other_time = df_sorted.iloc[top_N:]["Time_ms"].sum()
        
        # Create a new row for "other"
        other_row = pd.DataFrame({
            "Name": ["Other"],
            "Time_ms": [other_time]
        })
        
        # Combine top N with the "other" row
        df_plot = pd.concat([top_n[["Name", "Time_ms"]], other_row], ignore_index=True)
    else:
        df_plot = df_sorted[["Name", "Time_ms"]]
    
    # Extract data for plotting
    labels = df_plot["Name"].tolist()
    times = df_plot["Time_ms"].tolist()
    if per_elem:
        times=times/df["# of Calls"]
    if bar:
        plt.bar(labels, times, edgecolor="black")
        plt.xlabel("Operation")
        plt.ylabel("Time (ms)")
        plt.xticks(rotation=45)
        if per_elem:
            plt.ylabel("Time per call (ms)")
            
    else:
        plt.pie(times, autopct='%1.1f%%', labels=labels, wedgeprops=wedgeprops)
        #plt.legend(labels, loc="best")
        
    if aten:
        plt.title("AIFS GPU aten breakdown")
    else:
        plt.title("AIFS GPU compute breakdown")
        
    if aten:
        plt.savefig(f"{outdir}/aten.png")
    else:
        plt.savefig(f"{outdir}/compute.png")
    plt.show()
    plt.clf()
    

def plot_memcpy(df, outdir, per_elem=False, bar=False):
    df=get_memcpy_results(df)
    labels=df["Name"].tolist()
    times=df["Self CUDA"].apply(convert_to_ms)
    if per_elem:
        times=times/df["# of Calls"]
    if bar:
        plt.bar(labels, times, edgecolor="black")
        plt.xlabel("Operation")
        plt.ylabel("Time (ms)")
        plt.xticks(rotation=45)
        if per_elem:
            plt.ylabel("Time per call (ms)")
        plt.legend()
            
    else:
        plt.pie(times, autopct='%1.1f%%',wedgeprops=wedgeprops)
        plt.legend(labels, loc="best")
        
    plt.title("AIFS memory Operations")
    if per_elem:
        plt.title("AIFS memcpy Operations per call")
    #plt.legend(title="Source Resolution")
    plt.tight_layout()
    #plt.xscale("log")
    plt.savefig(f"{outdir}/memory.png")
    plt.show()
    plt.clf()
    
def plot_nccl(df, outdir, per_elem=False, bar=False):
    df=get_nccl_results(df)
    labels=df["Name"].tolist()
    times=df["Self CUDA"].apply(convert_to_ms)
    if per_elem:
        times=times/df["# of Calls"]
    if bar:
        plt.bar(labels, times, edgecolor="black")
        plt.xlabel("Operation")
        plt.ylabel("Time (ms)")
        plt.xticks(rotation=45)
        if per_elem:
            plt.ylabel("Time per call (ms)")
        plt.legend()
            
    else:
        plt.pie(times, autopct='%1.1f%%',wedgeprops=wedgeprops)
        plt.legend(labels, loc="best")
        
    plt.title("AIFS NCCL Operations")
    if per_elem:
        plt.title("AIFS NCCL Operations per call")
    #plt.legend(title="Source Resolution")
    plt.tight_layout()
    #plt.xscale("log")
    plt.savefig(f"{outdir}/nccl.png")
    plt.show()
    plt.clf()
    
def plot_gpu_comms_memcpy_compute_breakdown(df, outdir):
    df=gpu_only(df)
    nccl_df=get_nccl_results(df)
    #print(nccl_df)
    memcpy_df=get_memcpy_results(df)
    compute_df=get_compute_results(df)
    
    nccl_total = sum_cuda_time(nccl_df)
    memcpy_total = sum_cuda_time(memcpy_df)
    compute_total = sum_cuda_time(compute_df)
    
    # Prepare data for pie chart
    labels = ["NCCL", "Memory", "Compute"]
    values = [nccl_total, memcpy_total, compute_total]
    
    # Calculate percentages for better labels
    total = sum(values)
    percentages = [(val/total)*100 for val in values]
    labels_with_pct = [f'{label} ({pct:.1f}%)' for label, pct in zip(labels, percentages)]
    
    # Create custom colors for better visualization
    colors = ['#ff9999', '#66b3ff', '#99ff99']
    
    # Create figure
    plt.figure()
    
    # Create pie chart
    #plt.pie(values, labels=labels_with_pct, colors=colors)
    plt.pie(values, autopct='%1.1f%%',wedgeprops=wedgeprops)
    plt.legend(labels, loc="best")
            #autopct='%1.1f%%', startangle=90, shadow=True)
    
    # Equal aspect ratio ensures that pie is drawn as a circle
    #plt.axis('equal')
    
    # Add title
    plt.title('GPU runtime breakdown')
    plt.tight_layout()
    
    # Print the actual values for reference
    #print(f"NCCL: {nccl_total:.2f} ms")
    #print(f"Memory Copy: {memcpy_total:.2f} ms")
    #print(f"Compute: {compute_total:.2f} ms")
    #print(f"Total: {total:.2f} ms")
    
    plt.savefig(f"{outdir}/gpu-breakdown.png")
    plt.show()
    plt.clf()
    
def sort_dataframe_by_custom_order(df):
    # Define the custom order
    custom_order = ['anemoi-encoder', 'anemoi-processor', 'anemoi-decoder']
    
    # Convert the Name column to a Categorical data type with the custom order
    df.loc[:, 'Name'] = pd.Categorical(df['Name'], categories=custom_order, ordered=True)
    
    # Sort the DataFrame by the Name column
    sorted_df = df.sort_values('Name').reset_index(drop=True)
    
    # Convert back to normal string (optional)
    sorted_df['Name'] = sorted_df['Name'].astype(str)
    
    return sorted_df  


def get_largest_per_name(df):
    # Group by 'Name' and find the row with the maximum 'time_per_step_ms' in each group
    df_largest = df.loc[df.groupby('Name')['time_per_step_ms'].idxmax()]
    
    # Reset the index for cleaner output
    df_largest = df_largest.reset_index(drop=True)
    
    return df_largest

#TODO hardcode the colours to names
def plot_anemoi(df, outdir, bar=True, enc_proc_dec=False, per_step=False):
    df = df[df["Name"].str.startswith("anemoi-")] #filter to just anemoi markers from nvtx_wrapper
    #df = df[df["Self CUDA"] != "0.000us"] #filter out events with no cuda time 
    y_val="CUDA total"
    if enc_proc_dec:
        df = sort_dataframe_by_custom_order(filter_anemoi_names(df))
    else:
        df=df.sort_values(by=[y_val + ' ms'])
        
    #df["time_per_step_ms"] = df["Self CUDA"].apply(convert_to_ms)/df["# of Calls"]
    df["time_per_step_ms"] = df[y_val].apply(convert_to_ms)/df["# of Calls"]
    df=get_largest_per_name(df) #because we profiler cpu and GPU, we have double entries here, remove the smallest one
    #print(df[["Name", "# of Calls", "Self CUDA", "CUDA total", "time_per_step_ms"]])
    xs=df["Name"].tolist()
    if per_step:
        ys=df["time_per_step_ms"].tolist()
    else:
        ys=df[y_val + ' ms'].tolist()
    #ys=df["time_per_step_ms"].tolist()
    #print(f"{xs=}, {ys=}")
    if bar:
        plt.bar(xs, ys, color='skyblue', edgecolor='black')
        plt.ylabel("Training Step Time (s)")
        plt.xticks(rotation=90)
    else:
        plt.pie(ys, autopct='%1.1f%%',wedgeprops=wedgeprops)
        plt.legend(labels=xs, loc='best')
        plt.tight_layout()
    #plt.pie(ys, labels=xs)
    
    plt.title("AIFS training forward pass breakdown")
    #plt.legend(title="Source Resolution")
    plt.grid(True)
    #plt.xscale("log")
    
    if enc_proc_dec:
        plt.savefig(f"{outdir}/raps-test-encprocdec.png")
    else:
        plt.savefig(f"{outdir}/raps-test-anemoi.png")
    plt.show()
    plt.clf()
    
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("rundir")
    parser.add_argument("-o", "--outdir", default=".")
    args = parser.parse_args()
    
    #run_id=`awk '/INFO Adding extra information to checkpoint/ {match($0, /\/([^/]+)\/[^/]+$/, arr); print arr[1]; exit}' $rundir/out.txt`
    #csv=
    import pathlib
    path=list(pathlib.Path(f"{args.rundir}/train-outputs/profiler/").rglob('memory_profiler.csv'))[0]

    df = pd.read_csv(path)
    df["Self CUDA ms"] = df["Self CUDA"].apply(convert_to_ms)
    df["CUDA total ms"] = df["CUDA total"].apply(convert_to_ms)

    #print(df.head())

    plot_nccl(df, args.outdir)

    plot_anemoi(df, args.outdir, bar=False, enc_proc_dec=True)
    plot_memcpy(df, args.outdir)
    plot_compute(df, args.outdir, bar=False, top_N=8)
    plot_compute(df, args.outdir, bar=False, top_N=8, aten=True)
    plot_gpu_comms_memcpy_compute_breakdown(df, args.outdir)

if __name__ == "__main__":
    main()
