# How to use
This folder contains json files to be used with nsight to trace python functions. An example command is shown below
```bash
module load nvidia/24.11
nsys_cmd="nsys profile -o anemoi_${SLURM_JOB_ID} --python-functions-trace=/perm/naco/profiling/nsys/PythonFunctionsTrace/anemoi.json"
$nsys_cmd srun anemoi-training
```
The functions listed in the Json file will appear in the nsight profile. Both forward and backward pass is profiled, and the host function calls are linked to the relevant device kernels

# How to generate
You can use the script scripts/generate\_json.sh to generate an updated json file. You just need to edit the code to link to your new anemoi models dir. If you want to include pytorch annotations in your file you should edit the path to point to a copy of pytorch.json (can be found under nsys v25 and newer install dir)
```bash
bash scripts/generate_json.sh new_anemoi.json
```
