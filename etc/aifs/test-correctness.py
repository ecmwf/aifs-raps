# (C) Copyright 2025- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

import sys
import os
import re
import numpy as np

from scipy.stats import ttest_ind as ttest

def extract_run_id(out_txt_path):
    """Extract run_id from the out.txt file."""
    try:
        with open(out_txt_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                if "INFO Adding extra information to checkpoint" in line:
                    match = re.search(r'/([^/]+)/[^/]+$', line)
                    if match:
                        return match.group(1)
    except FileNotFoundError:
        pass
    return None


def get_mlflow_experiment_name(mlflow_logs_dir):
    """Get the MLflow experiment directory name (first entry matching word characters)."""
    try:
        for entry in os.listdir(mlflow_logs_dir):
            if re.match(r'^\w+', entry):
                return entry
    except FileNotFoundError:
        pass
    return None

def get_run_id(run_id_dir):
    try:
        for entry in os.listdir(run_id_dir):
            if re.match(r'^\w+', entry) and entry != "meta.yaml":
                return entry
    except FileNotFoundError:
        pass
    return None

def extract_loss_at_step(filepath, step=4999):
    """Extract the loss value for a given step from the metrics file."""
    try:
        with open(filepath, 'r') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) >= 3 and parts[2] == str(step):
                    return parts[1]
    except FileNotFoundError:
        pass
    return None

def extract_latest_loss(filepath):
    """Extract the loss value at last current step from the metrics file."""
    try:
        with open(filepath, 'r') as f:
            last_line = None
            for line in f:
                last_line = line
            if last_line:
                parts = last_line.strip().split()
                if len(parts) >= 3:
                    return parts[1], parts[2]
    except FileNotFoundError:
        pass
    return None, None

# Main execution starts here
input_rundir_list = sys.argv[1:]


losses=[]
for rundir in input_rundir_list:
    run_name=rundir.split("/")[-1]
    out_txt_path = os.path.join(rundir, 'out.txt')

    #run_id = extract_run_id(out_txt_path)
    #if not run_id:
    #    print(f"Can't extract run_id for run '{run_name}'")
    #    continue

    mlflow_logs_dir = os.path.join(rundir, 'train-outputs', 'logs', 'mlflow')
    mlflow_exp_name = get_mlflow_experiment_name(mlflow_logs_dir)

    if not mlflow_exp_name:
        print(f"Can't find MLflow experiment for run '{run_name}'")
        continue

    run_id_dir =  os.path.join(mlflow_logs_dir,  mlflow_exp_name)
    run_id = get_run_id(run_id_dir)

    train_loss_step_path = os.path.join(
        mlflow_logs_dir, mlflow_exp_name, run_id, 'metrics', 'train_mse_loss_step'
    )

    step=4999
    #loss_value = extract_loss_at_step(train_loss_step_path, step=step) #includes only finished runs
    loss_value, step = extract_latest_loss(train_loss_step_path) # includes all runs, even those not finished
    if loss_value:
        #print(f"run {run_name}: {loss_value}")
        #print(f"{loss_value} (step {step})")
        losses.append(float(loss_value))
    else:
        print(f"Can't find loss at step {step} for run '{run_name}'")

# Compute and print statistics
if losses:
    mean_loss = np.mean(losses)
    std_loss = np.std(losses)
    length= len(losses)
    #print(f"Mean loss: {mean_loss:.6f}")
    #print(f"Standard deviation across {length} runs: {std_loss:.6f}")
else:
    print("No valid loss values found.")

#calculate ttest
if losses:
    score_to_pass= 0.0054
    #ground_truth = [0.005327364429831505, 0.005269720684736967, 0.005299062002450228, 0.005297685973346233, 0.005312369205057621, 0.005360980052500963, 0.005294295027852058, 0.0052947793155908585, 0.005279442761093378]
    result = mean_loss <= score_to_pass
    print(f"mean loss of {mean_loss:.4f} versus {score_to_pass} reference (lower is better)")
    if result:
        print("PASS")
    else:
        print("FAIL")
