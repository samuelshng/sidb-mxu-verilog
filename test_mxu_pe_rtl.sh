#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Starting Verilog compilation and simulation..."

# Compile the Verilog files
echo "Compiling Verilog files..."
iverilog -o simulation tb/tb_mxu_pe.v rtl/mxu_pe.v rtl/mxu_pe_forward.v

# Check if compilation was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed! Stopping.${NC}"
    exit 1
else
    echo -e "${GREEN}Compilation successful.${NC}"
fi

# Run the simulation
echo "Running simulation..."
vvp simulation

# Check if simulation was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Simulation failed!${NC}"
    exit 1
else
    echo -e "${GREEN}Simulation completed.${NC}"
fi

echo "All done!"
