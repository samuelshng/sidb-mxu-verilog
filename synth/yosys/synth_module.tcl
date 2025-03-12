# Converts high-level Verilog to gate-level netlist

# Read the Verilog design
yosys read_verilog $::env(INPUT_VERILOG)

# Perform high-level synthesis and optimization
yosys hierarchy -check -top $::env(TOP_MODULE)
yosys proc
yosys opt
yosys fsm
yosys opt
yosys memory
yosys opt

# Map to gate-level components
yosys techmap
yosys opt

# Map to AIG representation
yosys "abc -g AND"

# Final cleanup
yosys clean

# Generate reports
yosys stat

# Split multi-bit nets into scalar nets
yosys "splitnets -ports"
yosys opt

# Write the synthesized design
yosys "write_verilog -noattr $::env(OUTPUT_VERILOG)"

# Generate a dot file for the design
yosys "show -format dot -prefix $::env(DIAGRAM_PREFIX)" 
