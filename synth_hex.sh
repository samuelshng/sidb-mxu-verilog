#!/bin/bash

# NOTE: This script is expected to be run from the root of the repository

set -e

# Set paths
mapped_dir=$(pwd)
gate_level_verilog_path="collab/mxu_pe_forward_synth_deepsyn57600_1.v"
output_dir="collab/fiction_synth_out"

# Create output directory if it doesn't exist
mkdir -p $output_dir

# Define repositories and commit hashes
CDA_TUM_REPO="https://github.com/cda-tum/fiction.git"
CDA_TUM_COMMIT="acc4444"
CDA_TUM_FOM_COMMIT="bdf1413"

echo "Building Docker images..."

# Build the base image first
docker build -q -t fiction-base:latest -f synth/fiction/Dockerfile.base .

# Build the runtime Docker images using the parameterized Dockerfile
docker build -q -t fiction-cda-tum:$CDA_TUM_COMMIT \
  --build-arg BASE_IMAGE=fiction-base:latest \
  --build-arg REPO_URL=$CDA_TUM_REPO \
  --build-arg COMMIT_HASH=$CDA_TUM_COMMIT \
  -f synth/fiction/Dockerfile.runtime .

docker build -q -t fiction-cda-tum:$CDA_TUM_FOM_COMMIT \
  --build-arg BASE_IMAGE=fiction-base:latest \
  --build-arg REPO_URL=$CDA_TUM_REPO \
  --build-arg COMMIT_HASH=$CDA_TUM_FOM_COMMIT \
  -f synth/fiction/Dockerfile.runtime .

echo "Docker images built successfully"

# Run fiction (cda-tum) with access to the current directory
fiction_cda_tum() {
    docker run --rm -v "$mapped_dir:/data" -w /data fiction-cda-tum:$CDA_TUM_COMMIT /app/fiction/build/cli/fiction "$@"
}

# Run fiction (cda-tum, FOM branch) with access to the current directory
fiction_cda_tum_fom() {
    docker run --rm -v "$mapped_dir:/data" -w /data fiction-cda-tum:$CDA_TUM_FOM_COMMIT /app/fiction/build/cli/fiction "$@"
}

# Uncomment to print help command to check if the Docker image is working
# fiction_cda_tum --help

########################################################
# Technology Mapping
########################################################

# Pre-run vanilla Bestagon mapping
echo "Running vanilla Bestagon mapping..."
fiction_cda_tum -c "
    read /data/$gate_level_verilog_path -a;
    map --and --or --inv --nand --nor --xor --xnor;
    ps -n;
    blif /data/$output_dir/bestagon.blif;
"
echo "Vanilla Bestagon mapping written to $output_dir/bestagon.blif"
echo ""

# Pre-run FoM Bestagon mapping
echo "Running FoM Bestagon mapping..."
fiction_cda_tum_fom -c "
    read /data/$gate_level_verilog_path -a;
    map --and --or --inv --nand --nor --xor --xnor;
    ps -n;
    blif /data/$output_dir/bestagon-fom.blif;
"
echo "FoM Bestagon mapping written to $output_dir/bestagon-fom.blif"
echo ""

# Pre-run --all2 mapping
echo "Running --all2 mapping..."
fiction_cda_tum -c "
    read /data/$gate_level_verilog_path -a;
    map --all2;
    ps -n;
    blif /data/$output_dir/all2.blif;
"
echo "All2 mapping written to $output_dir/all2.blif"
echo ""

# Pre-run FoM --all2 mapping
echo "Running FoM --all2 mapping..."
fiction_cda_tum_fom -c "
    read /data/$gate_level_verilog_path -a;
    map --all2;
    ps -n;
    blif /data/$output_dir/all2-fom.blif;
"
echo "FoM --all2 mapping written to $output_dir/all2-fom.blif"
echo ""

########################################################
# P&R, Optimization, Hexagonalization
########################################################

# exp1: vanilla Bestagon mapping + ortho
echo "Exp 1: Running vanilla Bestagon mapping + ortho..."
fiction_cda_tum -c "
    read /data/$output_dir/bestagon.blif -t;
    ortho;
    fgl /data/$output_dir/bestagon_ortho.fgl;
    ps -g;
    optimize -m 1;
    fgl /data/$output_dir/bestagon_ortho_opt.fgl;
    ps -g;
    hex;
    fgl /data/$output_dir/bestagon_ortho_opt_hex.fgl;
    ps -g;
"
echo "Vanilla mapping + ortho written to $output_dir/bestagon_ortho_opt_hex.fgl"
echo ""

# exp2: --all2 mapping + ortho
echo "Exp 2: Running --all2 mapping + ortho..."
fiction_cda_tum -c "
    read /data/$output_dir/all2.blif -t;
    ortho;
    fgl /data/$output_dir/all2_ortho.fgl;
    ps -g;
    optimize -m 1;
    fgl /data/$output_dir/all2_ortho_opt.fgl;
    ps -g;
    hex;
    fgl /data/$output_dir/all2_ortho_opt_hex.fgl;
    ps -g;
"
echo "All2 mapping + ortho written to $output_dir/all2_ortho_opt_hex.fgl"
echo ""

# exp3: FoM Bestagon mapping + ortho
echo "Exp 3: Running FoM Bestagon mapping + ortho..."
fiction_cda_tum -c "
    read /data/$output_dir/bestagon-fom.blif -t;
    ortho;
    ps -g;
    optimize -m 1;
    fgl /data/$output_dir/bestagon-fom_ortho_opt.fgl;
    ps -g;
    hex;
    fgl /data/$output_dir/bestagon-fom_ortho_opt_hex.fgl;
    ps -g;
"
echo "FoM Bestagon mapping + ortho written to $output_dir/bestagon-fom_ortho_opt_hex.fgl"
echo ""


# exp4: FoM all2 mapping + ortho
echo "Exp 4: Running FoM all2 mapping + ortho..."
fiction_cda_tum -c "
    read /data/$output_dir/all2-fom.blif -t;
    ortho;
    ps -g;
    optimize -m 1;
    fgl /data/$output_dir/all2-fom_ortho_opt.fgl;
    ps -g;
    hex;
    fgl /data/$output_dir/all2-fom_ortho_opt_hex.fgl;
    ps -g;
"
echo "FoM all2 mapping + ortho written to $output_dir/all2-fom_ortho_opt_hex.fgl"
echo ""

# Create an array of all result files
result_files=(
    "bestagon_ortho_opt_hex.fgl"
    "all2_ortho_opt_hex.fgl" 
    "bestagon-fom_ortho_opt_hex.fgl"
    "all2-fom_ortho_opt_hex.fgl"
)

echo "Summarizing all results..."
for result in "${result_files[@]}"; do
    echo "Results for $result:"
    fiction_cda_tum -c "
        read -f /data/$output_dir/$result even_row_hex;
        ps -g;
    "
    echo ""
done
