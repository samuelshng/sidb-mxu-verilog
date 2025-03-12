module mxu_pe_forward #(
    parameter Y_INDEX = 0  // Internal y-index for this processing element
) (
    // Control signals
    input wire load_phase,  // 0 = No-op, 1 = Preload
    input wire [7:0] load_weight_target_y,  // Target y-index processing element for weight load
    input wire [7:0] load_weight,  // Load weight input
    // Core MAC I/O
    input wire [7:0] weight_mem,  // Weight from delay line memory
    input wire [7:0] activation,  // Activation input
    input wire [23:0] partial_sum,  // Incoming partial sum
    output wire [23:0] result,  // MAC result: partial_sum + (weight * activation)
    // Passthroughs
    output wire phase_out,  // Passthrough of phase
    output wire [7:0] load_weight_target_y_out,  // Passthrough of target y-index processing element for weight load
    output wire [7:0] activation_out,  // Passthrough of activation
    output wire [7:0] weight_out,  // Passthrough of weight
    // Weight out for delay line memory
    output wire [7:0] weight_mem_out  // Weight out for delay line memory
);

  // Phase constants defining the operation modes of the PE
  localparam NO_OP_PHASE = 1'b0;
  localparam PRELOAD_PHASE = 1'b1;

  // Compute the 8x8 multiplication.
  // For a combinational implementation, we compute the product in one continuous assignment.
  wire [15:0] product;
  assign product = $signed(weight_mem) * $signed(activation);

  // Extend the 16-bit product to 24 bits with sign extension
  wire [23:0] product_ext;
  assign product_ext = {{8{product[15]}}, product};

  // Compute the MAC output
  assign result = partial_sum + product_ext;

  // Top-down passthroughs
  assign phase_out = load_phase;
  assign load_weight_target_y_out = load_weight_target_y;
  assign weight_out = load_weight;

  // Left-right passthroughs
  assign activation_out = activation;

  // Delay line memory behavior
  // If phase = 1 (preload) and load_weight_target_y == Y_INDEX: set weight_mem_out = load_weight
  // Otherwise: weight_mem_out = weight_mem
  assign weight_mem_out = (load_phase == PRELOAD_PHASE && load_weight_target_y == Y_INDEX) ? load_weight : weight_mem;

endmodule
