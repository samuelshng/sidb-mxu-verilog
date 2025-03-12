module mxu_pe #(
    parameter Y_INDEX = 0  // Internal y-index for this processing element
) (
    // Clock and reset
    input wire clk,  // Clock signal
    input wire rst_n,  // Active-low reset
    // Control signals
    input wire load_phase,  // 0 = No-op, 1 = Preload
    input wire [7:0] load_weight_target_y,  // Target y-index processing element for weight load
    input wire [7:0] load_weight,  // Load weight input
    // Core MAC I/O
    input wire [7:0] activation,  // Activation input
    input wire [23:0] partial_sum,  // Incoming partial sum
    output reg [23:0] result,  // MAC result: partial_sum + (weight * activation)
    // Passthroughs
    output reg phase_out,  // Passthrough of phase
    output reg [7:0] load_weight_target_y_out,  // Passthrough of target y-index processing element for weight load
    output reg [7:0] weight_out,  // Passthrough of weight
    // Backward pass outputs
    output reg [7:0] activation_out_bw  // Backward activation output
);

  // Register all inputs to forward_pe to ensure consistent timing
  reg [7:0] activation_reg;
  reg load_phase_reg;
  reg [7:0] load_weight_target_y_reg;
  reg [7:0] load_weight_reg;
  reg [23:0] partial_sum_reg;

  // Register all inputs on the same clock edge
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      activation_reg <= 8'b0;
      load_phase_reg <= 1'b0;
      load_weight_target_y_reg <= 8'b0;
      load_weight_reg <= 8'b0;
      partial_sum_reg <= 24'b0;
    end else begin
      activation_reg <= activation;
      load_phase_reg <= load_phase;
      load_weight_target_y_reg <= load_weight_target_y;
      load_weight_reg <= load_weight;
      partial_sum_reg <= partial_sum;
    end
  end

  // Stage 0 - Forward PE outputs
  wire [23:0] stage0_result;
  wire stage0_phase_out;
  wire [7:0] stage0_load_weight_target_y_out;
  wire [7:0] stage0_activation_out;
  wire [7:0] stage0_weight_out;
  wire [7:0] stage0_weight_mem_out;

  // Stage 1 registers - store outputs from stage 0
  reg [23:0] stage1_result;
  reg stage1_phase_out;
  reg [7:0] stage1_load_weight_target_y_out;
  reg [7:0] stage1_activation_out;
  reg [7:0] stage1_weight_out;
  reg [7:0] stage1_weight_mem_out;

  // Stage 2 registers - store outputs from stage 1
  reg [23:0] stage2_result;
  reg stage2_phase_out;
  reg [7:0] stage2_load_weight_target_y_out;
  reg [7:0] stage2_activation_out;
  reg [7:0] stage2_weight_out;
  reg [7:0] stage2_weight_mem_out;

  // Stage 3 registers - store outputs from stage 2
  reg [7:0] stage3_activation_out;
  reg [7:0] stage3_weight_mem_out;

  // Stage 4 registers - store outputs from stage 3
  reg [7:0] stage4_weight_mem_out;

  // Instantiate the forward processing element (Stage 0)
  mxu_pe_forward #(
      .Y_INDEX(Y_INDEX)
  ) forward_pe (
      .load_phase(load_phase_reg),
      .load_weight_target_y(load_weight_target_y_reg),
      .load_weight(load_weight_reg),
      .weight_mem(stage4_weight_mem_out),
      .activation(activation_reg),
      .partial_sum(partial_sum_reg),
      .result(stage0_result),
      .phase_out(stage0_phase_out),
      .load_weight_target_y_out(stage0_load_weight_target_y_out),
      .activation_out(stage0_activation_out),
      .weight_out(stage0_weight_out),
      .weight_mem_out(stage0_weight_mem_out)
  );

  // Stage 0 to Stage 1 pipeline registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_result <= 24'b0;
      stage1_phase_out <= 1'b0;
      stage1_load_weight_target_y_out <= 8'b0;
      stage1_activation_out <= 8'b0;
      stage1_weight_out <= 8'b0;
      stage1_weight_mem_out <= 8'b0;
    end else begin
      stage1_result <= stage0_result;
      stage1_phase_out <= stage0_phase_out;
      stage1_load_weight_target_y_out <= stage0_load_weight_target_y_out;
      stage1_activation_out <= stage0_activation_out;
      stage1_weight_out <= stage0_weight_out;
      stage1_weight_mem_out <= stage0_weight_mem_out;
    end
  end

  // Stage 1 to Stage 2 pipeline registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage2_result <= 24'b0;
      stage2_phase_out <= 1'b0;
      stage2_load_weight_target_y_out <= 8'b0;
      stage2_activation_out <= 8'b0;
      stage2_weight_out <= 8'b0;
      stage2_weight_mem_out <= 8'b0;
    end else begin
      stage2_result <= stage1_result;
      stage2_phase_out <= stage1_phase_out;
      stage2_load_weight_target_y_out <= stage1_load_weight_target_y_out;
      stage2_activation_out <= stage1_activation_out;
      stage2_weight_out <= stage1_weight_out;
      stage2_weight_mem_out <= stage1_weight_mem_out;
    end
  end

  // Stage 2 to Stage 3 pipeline registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage3_activation_out <= 8'b0;
      stage3_weight_mem_out <= 8'b0;
    end else begin
      stage3_activation_out <= stage2_activation_out;
      stage3_weight_mem_out <= stage2_weight_mem_out;
    end
  end

  // Stage 3 to Stage 4 pipeline registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage4_weight_mem_out <= 8'b0;
    end else begin
      stage4_weight_mem_out <= stage3_weight_mem_out;
    end
  end

  // Stage 0 outputs to module outputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      result <= 24'b0;
      phase_out <= 1'b0;
      load_weight_target_y_out <= 8'b0;
      weight_out <= 8'b0;
    end else begin
      result <= stage1_result;
      phase_out <= stage1_phase_out;
      load_weight_target_y_out <= stage1_load_weight_target_y_out;
      weight_out <= stage1_weight_out;
    end
  end

  // Stage 4 output to backward activation output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      activation_out_bw <= 8'b0;
    end else begin
      activation_out_bw <= stage3_activation_out;
    end
  end

endmodule
