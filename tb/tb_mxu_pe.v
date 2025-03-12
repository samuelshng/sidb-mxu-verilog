module tb_mxu_pe;
  // Clock and reset
  reg clk;
  reg rst_n;

  // Inputs
  reg load_phase;
  reg [7:0] load_weight_target_y;
  reg [7:0] load_weight;
  reg [7:0] activation;
  reg [23:0] partial_sum;

  // Outputs
  wire [23:0] result;
  wire phase_out;
  wire [7:0] load_weight_target_y_out;
  wire [7:0] weight_out;
  wire [7:0] activation_out_bw;

  // Error counter
  integer errors;

  // Instantiate the Device Under Test (DUT)
  mxu_pe #(
      .Y_INDEX(8'd5)  // Using an arbitrary Y_INDEX value for testing
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .load_phase(load_phase),
      .load_weight_target_y(load_weight_target_y),
      .load_weight(load_weight),
      .activation(activation),
      .partial_sum(partial_sum),
      .result(result),
      .phase_out(phase_out),
      .load_weight_target_y_out(load_weight_target_y_out),
      .weight_out(weight_out),
      .activation_out_bw(activation_out_bw)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns clock period
  end

  // Task to initialize all inputs to default values
  task init_inputs;
    begin
      load_phase = 1'b0;
      load_weight_target_y = 8'd0;
      load_weight = 8'd0;
      activation = 8'd0;
      partial_sum = 24'd0;
    end
  endtask

  // Task to clear the MXU prior to a new test
  task clear_mxu;
    begin
      init_inputs();
      rst_n = 0;
      @(posedge clk);
      rst_n = 1;
      @(posedge clk);
    end
  endtask

  // Main test sequence
  initial begin
    $display("Starting MXU_PE testbench...");
    errors = 0;

    // Initialize signals
    clear_mxu();

    // Apply reset for a few clock cycles
    // ===== Test Case 1: Forward passthrough =====
    $display("\n===== Test Case 1: Forward passthrough =====");

    // Verify forward path passthroughs (load_phase, load_weight_target_y, load_weight) over 2 clock cycles
    load_phase = 1'b1;
    load_weight_target_y = 8'd5;
    load_weight = 8'd10;
    @(posedge clk);
    load_phase = 1'b0;
    load_weight_target_y = 8'd6;
    load_weight = 8'd20;
    @(posedge clk);
    #1;

    if (phase_out !== 1'b1) begin
      $display("Error: expected phase_out=1, got %b", phase_out);
      errors++;
    end else if (load_weight_target_y_out !== 8'd5) begin
      $display("Error: expected load_weight_target_y_out=5, got %d", load_weight_target_y_out);
      errors++;
    end else if (weight_out !== 8'd10) begin
      $display("Error: expected weight_out=10, got %d", weight_out);
      errors++;
    end else begin
      $display("Test 1.1 passed: forward path passthroughs");
    end

    @(posedge clk);
    #1;

    if (phase_out !== 1'b0) begin
      $display("Error: expected phase_out=0, got %b", phase_out);
      errors++;
    end else if (load_weight_target_y_out !== 8'd6) begin
      $display("Error: expected load_weight_target_y_out=6, got %d", load_weight_target_y_out);
      errors++;
    end else if (weight_out !== 8'd20) begin
      $display("Error: expected weight_out=20, got %d", weight_out);
      errors++;
    end else begin
      $display("Test 1.2 passed: forward path passthroughs");
    end


    // ===== Test Case 2: Test backward path activation =====
    $display("\n===== Test Case 2: Test backward path activation =====");

    // Reset for a clean test
    clear_mxu();

    // Set activation to 4 different values in consecutive clock cycles
    activation = 8'd99;
    @(posedge clk);
    activation = 8'd100;
    #1;
    $display("stage1_activation_out = %d", dut.stage1_activation_out);
    $display("stage2_activation_out = %d", dut.stage2_activation_out);
    $display("stage3_activation_out = %d", dut.stage3_activation_out);
    $display("activation_out_bw = %d", activation_out_bw);
    $display("");
    @(posedge clk);
    activation = 8'd101;
    #1;
    $display("stage1_activation_out = %d", dut.stage1_activation_out);
    $display("stage2_activation_out = %d", dut.stage2_activation_out);
    $display("stage3_activation_out = %d", dut.stage3_activation_out);
    $display("activation_out_bw = %d", activation_out_bw);
    $display("");
    @(posedge clk);
    activation = 8'd102;
    #1;
    $display("stage1_activation_out = %d", dut.stage1_activation_out);
    $display("stage2_activation_out = %d", dut.stage2_activation_out);
    $display("stage3_activation_out = %d", dut.stage3_activation_out);
    $display("activation_out_bw = %d", activation_out_bw);
    $display("");
    @(posedge clk);
    activation = 8'd0;
    #1;
    $display("stage1_activation_out = %d", dut.stage1_activation_out);
    $display("stage2_activation_out = %d", dut.stage2_activation_out);
    $display("stage3_activation_out = %d", dut.stage3_activation_out);
    $display("activation_out_bw = %d", activation_out_bw);
    $display("");

    if (activation_out_bw !== 8'd99) begin
      $display("Error: Backward path failed. Expected activation_out_bw=99, got %d",
               activation_out_bw);
      errors++;
    end else begin
      $display("Test 2.1 passed: Activation passes to backward path correctly");
    end

    @(posedge clk);
    #1;

    if (activation_out_bw !== 8'd100) begin
      $display("Error: Backward path failed. Expected activation_out_bw=100, got %d",
               activation_out_bw);
      errors++;
    end else begin
      $display("Test 2.2 passed: Activation passes to backward path correctly");
    end

    @(posedge clk);
    #1;

    if (activation_out_bw !== 8'd101) begin
      $display("Error: Backward path failed. Expected activation_out_bw=101, got %d",
               activation_out_bw);
      errors++;
    end else begin
      $display("Test 2.3 passed: Activation passes to backward path correctly");
    end

    @(posedge clk);
    #1;

    if (activation_out_bw !== 8'd102) begin
      $display("Error: Backward path failed. Expected activation_out_bw=102, got %d",
               activation_out_bw);
      errors++;
    end else begin
      $display("Test 2.4 passed: Activation passes to backward path correctly");
    end


    // ===== Test Case 3: Test delay line memory for weights =====
    $display("\n===== Test Case 3: Test delay line memory for weights =====");

    // Reset for a clean test
    clear_mxu();

    // When load_phase = 1, delay line memory should return the loaded weight 4 clock cycles later
    // In this test, 4 consecutive different weights are loaded
    load_phase = 1'b1;
    load_weight_target_y = 8'd5;
    load_weight = 8'd10;
    @(posedge clk);
    load_weight = 8'd20;
    @(posedge clk);
    load_weight = 8'd30;
    @(posedge clk);
    load_weight = 8'd40;
    @(posedge clk);
    // End of loading, set a different weight to test that it doesn't contaminate the weight memory when load_phase = 0
    load_phase  = 1'b0;
    load_weight = 8'd1;
    #1;

    if (dut.stage4_weight_mem_out !== 8'd10) begin
      $display("Error: Weight loading failed. Expected stage4_weight_mem_out=10, got %d",
               dut.stage4_weight_mem_out);
      errors++;
    end else begin
      $display("Test 3.1 passed: Weight loading passed");
    end

    @(posedge clk);
    #1;

    if (dut.stage4_weight_mem_out !== 8'd20) begin
      $display("Error: Weight loading failed. Expected stage4_weight_mem_out=20, got %d",
               dut.stage4_weight_mem_out);
      errors++;
    end else begin
      $display("Test 3.2 passed: Weight loading passed");
    end

    @(posedge clk);
    #1;

    if (dut.stage4_weight_mem_out !== 8'd30) begin
      $display("Error: Weight loading failed. Expected stage4_weight_mem_out=30, got %d",
               dut.stage4_weight_mem_out);
      errors++;
    end else begin
      $display("Test 3.3 passed: Weight loading passed");
    end

    @(posedge clk);
    #1;

    if (dut.stage4_weight_mem_out !== 8'd40) begin
      $display("Error: Weight loading failed. Expected stage4_weight_mem_out=40, got %d",
               dut.stage4_weight_mem_out);
      errors++;
    end else begin
      $display("Test 3.4 passed: Weight loading passed");
    end

    // Next 4 clock cycles should continue to return the weight in the delay line memory
    @(posedge clk);
    #1;

    if (dut.stage4_weight_mem_out !== 8'd10) begin
      $display(
          "Error: Anti-contamination of weight memory failed. Expected stage4_weight_mem_out=10, got %d",
          dut.stage4_weight_mem_out);
      errors++;
    end else begin
      $display("Test 3.5 passed: Weight loading passed");
    end

    @(posedge clk);
    #1;

    if (dut.stage4_weight_mem_out !== 8'd20) begin
      $display(
          "Error: Anti-contamination of weight memory failed. Expected stage4_weight_mem_out=20, got %d",
          dut.stage4_weight_mem_out);
      errors++;
    end else begin
      $display("Test 3.6 passed: Weight loading passed");
    end

    @(posedge clk);
    #1;

    if (dut.stage4_weight_mem_out !== 8'd30) begin
      $display(
          "Error: Anti-contamination of weight memory failed. Expected stage4_weight_mem_out=30, got %d",
          dut.stage4_weight_mem_out);
      errors++;
    end else begin
      $display("Test 3.7 passed: Weight loading passed");
    end

    @(posedge clk);
    #1;

    if (dut.stage4_weight_mem_out !== 8'd40) begin
      $display(
          "Error: Anti-contamination of weight memory failed. Expected stage4_weight_mem_out=40, got %d",
          dut.stage4_weight_mem_out);
      errors++;
    end else begin
      $display("Test 3.8 passed: Weight loading passed");
    end

    // ===== Test Case 4: Test MAC operation on simple numbers =====
    $display("\n===== Test Case 4: Test MAC operation on simple numbers =====");

    // Reset for a clean test
    clear_mxu();

    // First load four different weights
    load_phase = 1'b1;
    load_weight_target_y = 8'd5;
    load_weight = 8'd10;  // phase 1
    @(posedge clk);
    load_weight = 8'd20;  // phase 2
    @(posedge clk);
    load_weight = 8'd30;  // phase 3
    @(posedge clk);
    load_weight = 8'd40;  // phase 4
    @(posedge clk);

    // End of loading
    load_phase  = 1'b0;
    load_weight = 8'd0;

    // Set activation and partial sum
    activation  = 8'd10;  // phase 1
    partial_sum = 24'd1;
    @(posedge clk);
    activation = 8'd20;  // phase 2
    @(posedge clk);
    activation = 8'hE2;  // phase 3, -30 in 2's complement
    #1;

    // Phase 1: 10 * 10 + 1 = 101
    if (result !== 24'd101) begin
      $display("Error: MAC operation (10 * 10 + 1) failed. Expected result=101, got %d", result);
      errors++;
    end else begin
      $display("Test 4.1 passed: MAC operation passed");
    end

    @(posedge clk);
    activation = 8'd0;  // phase 4
    #1;

    // Phase 2: 20 * 20 + 1 = 401
    if (result !== 24'd401) begin
      $display("Error: MAC operation (20 * 20 + 1) failed. Expected result=401, got %d", result);
      errors++;
    end else begin
      $display("Test 4.2 passed: MAC operation passed");
    end

    @(posedge clk);
    #1;

    // Phase 3: -30 * 30 + 1 = -899 (in 2's complement that is 24'hFFFC7D)
    if (result !== 24'hFFFC7D) begin
      $display("Error: MAC operation (-30 * 30 + 1) failed. Expected result=899, got %d", result);
      errors++;
    end else begin
      $display("Test 4.3 passed: MAC operation passed");
    end

    @(posedge clk);
    #1;

    // Phase 4: 0 * 0 + 1 = 1
    if (result !== 24'd1) begin
      $display("Error: MAC operation (0 * 0 + 1) failed. Expected result=1, got %d", result);
      errors++;
    end else begin
      $display("Test 4.4 passed: MAC operation passed");
    end

    // ===== Test Case 5: Test MAC operation on large numbers =====
    $display("\n===== Test Case 5: Test MAC operation on large numbers =====");

    // Reset for a clean test
    clear_mxu();

    // TODO: implement

    // Summarize results
    $display("\n===== Test Summary =====");
    if (errors == 0) $display("All basic MXU_PE tests passed!");
    else $display("%d MXU_PE tests failed.", errors);

    $display("Testbench completed.");
    $finish;
  end
endmodule
