# SiDB MXU Implemented in Verilog

This repository contains the Verilog implementation of a processing element of the TPUv1's Matrix Multiply Unit (MXU).

## Dependencies

**To test and synthesize the Verilog:**

- Icarus Verilog (simulation)
- Yosys (synthesis)
- Graphviz (generating diagrams)

**To convert to SQD:**

- [fiction](https://fiction.readthedocs.io/en/latest/getting_started.html)

## Running Testbenches

Testing the combinatorial component:

```bash
./test_mxu_pe_forward.sh
```

Testing the 4-stage processing element:

```bash
./test_mxu_pe_rtl.sh
```

## Running Synthesis

### HLS to Gate-level

Use [`synth_module.sh`](./synth_module.sh):

```bash
# adder2_unsigned module
./synth_module.sh -m adder2_unsigned -i rtl/adder2_unsigned.v -o adder2_unsigned_synth.v
# mxu_pe_forward module
./synth_module.sh -m mxu_pe_forward -i rtl/mxu_pe_forward.v -o mxu_pe_forward_synth.v
```

### Gate-level to hex

[`synth_hex.sh`](./synth_hex.sh) does all the different combinations of gate-level to hex synthesis that this paper needs. Directly `tee`ing the log output to a file causes repetitive progress strings to be logged, so use the following command which filters out those lines.

```bash
./synth_hex.sh 2>&1 | grep --line-buffered -v "^.*\[G\[i\]" | tee collab/fiction_synth_out/fiction_synth.log
```
