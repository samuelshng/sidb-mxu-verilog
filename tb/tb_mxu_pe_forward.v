module tb_mxu_pe_forward;
  // Inputs
  reg            load_phase;
  reg     [ 7:0] load_weight_target_y;
  reg     [ 7:0] load_weight;
  reg     [ 7:0] weight_mem;
  reg     [ 7:0] activation;
  reg     [23:0] partial_sum;

  // Outputs
  wire    [23:0] result;
  wire           phase_out;
  wire    [ 7:0] load_weight_target_y_out;
  wire    [ 7:0] activation_out;
  wire    [ 7:0] weight_out;
  wire    [ 7:0] weight_mem_out;

  // Errors counter
  integer        errors;

  // Instantiate the Device Under Test (DUT)
  mxu_pe_forward #(
      .Y_INDEX(8'd5)  // Using a arbitrary Y_INDEX value for testing
  ) dut (
      .load_phase(load_phase),
      .load_weight_target_y(load_weight_target_y),
      .load_weight(load_weight),
      .weight_mem(weight_mem),
      .activation(activation),
      .partial_sum(partial_sum),
      .result(result),
      .phase_out(phase_out),
      .load_weight_target_y_out(load_weight_target_y_out),
      .activation_out(activation_out),
      .weight_out(weight_out),
      .weight_mem_out(weight_mem_out)
  );

  // Task to initialize all inputs to default values
  task init_inputs;
    begin
      load_phase = 1'b0;
      load_weight_target_y = 8'd0;
      load_weight = 8'd0;
      weight_mem = 8'd0;
      activation = 8'd0;
      partial_sum = 24'd0;
    end
  endtask

  initial begin
    $display("Starting PE_MXU_comb testbench...");
    errors = 0;

    // Test case 1:
    // load_phase = 0 should result in phase_out = 0
    init_inputs();
    load_phase = 1'b0;
    #1;  // Wait for 1 time unit for the combinational logic to propagate

    if (phase_out !== 1'b0) begin
      $display("Error: With load_phase=0, expected phase_out=0, got %b", phase_out);
      errors++;
    end else begin
      $display("Test case 1 passed: load_phase=0 -> phase_out=0");
    end

    // Test case 2:
    // load_phase = 1 and load_weight_target_y = internal Y_INDEX should result in:
    // * phase_out = 1
    // * weight_mem_out = load_weight
    init_inputs();
    load_phase = 1'b1;
    load_weight_target_y = 8'd5;
    load_weight = 8'd10;
    weight_mem = 8'd15;
    #1;

    if (phase_out !== 1'b1) begin
      $display("Error: With load_phase=1, expected phase_out=1, got %b", phase_out);
      errors++;
    end else if (weight_mem_out !== load_weight) begin
      $display("Error: With load_phase=1, expected weight_mem_out=%d, got %d", load_weight,
               weight_mem_out);
      errors++;
    end else if (load_weight_target_y_out !== load_weight_target_y) begin
      $display("Error: Expected load_weight_target_y_out=%d, got %d", load_weight_target_y,
               load_weight_target_y_out);
      errors++;
    end else begin
      $display(
          "Test case 2 passed: load_phase=1 -> phase_out=1, weight_mem_out=load_weight, load_weight_target_y_out correct");
    end

    // Test case 3:
    // load_phase = 1 and load_weight_target_y != internal Y_INDEX should result in:
    // * phase_out = 1
    // * weight_mem_out = weight_mem
    // * weight_out = load_weight
    init_inputs();
    load_phase = 1'b1;
    load_weight_target_y = 8'd0;
    load_weight = 8'd10;
    weight_mem = 8'd88;
    #1;

    if (phase_out !== 1'b1) begin
      $display("Error: With load_phase=1, expected phase_out=1, got %b", phase_out);
      errors++;
    end else if (weight_mem_out !== weight_mem) begin
      $display("Error: With load_phase=1, expected weight_mem_out=%d, got %d", weight_mem,
               weight_mem_out);
      errors++;
    end else if (weight_out !== load_weight) begin
      $display("Error: With load_phase=1, expected weight_out=%d, got %d", load_weight, weight_out);
      errors++;
    end else if (load_weight_target_y_out !== load_weight_target_y) begin
      $display("Error: Expected load_weight_target_y_out=%d, got %d", load_weight_target_y,
               load_weight_target_y_out);
      errors++;
    end else begin
      $display(
          "Test case 3 passed: load_phase=1 -> phase_out=1, weight_mem_out=weight_mem, weight_out=load_weight, load_weight_target_y_out correct");
    end

    // Test case 4: MAC Operation - Basic positive values
    init_inputs();
    weight_mem  = 8'd10;  // Positive weight
    activation  = 8'd5;  // Positive activation
    partial_sum = 24'd20;  // Initial partial sum
    #1;

    // Expected: 10 * 5 + 20 = 70
    if (result !== 24'd70) begin
      $display("Error: MAC Test 1 failed. Expected result=%d, got %d", 24'd70, result);
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 4 passed: MAC operation with positive values (10*5+20=70), activation passthrough correct");
    end

    // Test case 5: MAC Operation - Zero operands
    init_inputs();
    weight_mem  = 8'd0;  // Zero weight
    activation  = 8'd15;  // Positive activation
    partial_sum = 24'd30;  // Initial partial sum
    #1;

    // Expected: 0 * 15 + 30 = 30
    if (result !== 24'd30) begin
      $display("Error: MAC Test 2 failed. Expected result=%d, got %d", 24'd30, result);
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 5 passed: MAC operation with zero weight (0*15+30=30), activation passthrough correct");
    end

    // Test case 6: MAC Operation - Zero activation
    init_inputs();
    weight_mem  = 8'd25;  // Positive weight
    activation  = 8'd0;  // Zero activation
    partial_sum = 24'd40;  // Initial partial sum
    #1;

    // Expected: 25 * 0 + 40 = 40
    if (result !== 24'd40) begin
      $display("Error: MAC Test 3 failed. Expected result=%d, got %d", 24'd40, result);
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 6 passed: MAC operation with zero activation (25*0+40=40), activation passthrough correct");
    end

    // Test case 7: MAC Operation - Larger unsigned values
    init_inputs();
    weight_mem  = 8'd127;  // Large positive weight
    activation  = 8'd127;  // Large positive activation
    partial_sum = 24'd100;  // Initial partial sum
    #1;

    // Expected: 127 * 127 + 100 = 16,229
    if (result !== 24'd16229) begin
      $display("Error: MAC Test 4 failed. Expected result=%d, got %d", 24'd16229, result);
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 7 passed: MAC operation with large values (127*127+100=16229), activation passthrough correct");
    end

    // Test case 8: MAC Operation - Negative weight, positive activation
    init_inputs();
    weight_mem  = 8'hF0;  // -16 in 2's complement
    activation  = 8'd8;  // Positive activation
    partial_sum = 24'd50;  // Initial partial sum
    #1;

    // Expected: -16 * 8 + 50 = -78
    if ($signed(result) !== -24'd78) begin
      $display("Error: MAC Test 5 failed. Expected result=%d, got %d", -24'd78, $signed(result));
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 8 passed: MAC operation with negative weight (-16*8+50=-78), activation passthrough correct");
    end

    // Test case 9: MAC Operation - Positive weight, negative activation
    init_inputs();
    weight_mem  = 8'd12;  // Positive weight
    activation  = 8'hE0;  // -32 in 2's complement
    partial_sum = 24'd100;  // Initial partial sum
    #1;

    // Expected: 12 * -32 + 100 = -284
    if ($signed(result) !== -24'd284) begin
      $display("Error: MAC Test 6 failed. Expected result=%d, got %d", -24'd284, $signed(result));
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 9 passed: MAC operation with negative activation (12*-32+100=-284), activation passthrough correct");
    end

    // Test case 10: MAC Operation - Both negative values
    init_inputs();
    weight_mem  = 8'hF8;  // -8 in 2's complement
    activation  = 8'hEC;  // -20 in 2's complement
    partial_sum = 24'd50;  // Initial partial sum
    #1;

    // Expected: -8 * -20 + 50 = 210
    if (result !== 24'd210) begin
      $display("Error: MAC Test 7 failed. Expected result=%d, got %d", 24'd210, result);
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 10 passed: MAC operation with both negative values (-8*-20+50=210), activation passthrough correct");
    end

    // Test case 11: MAC Operation - Extreme signed values
    init_inputs();
    weight_mem  = 8'h80;  // -128 in 2's complement (minimum 8-bit signed value)
    activation  = 8'd127;  // 127 (maximum 8-bit signed value)
    partial_sum = 24'd0;  // Zero partial sum
    #1;

    // Expected: -128 * 127 = -16,256
    if ($signed(result) !== -24'd16256) begin
      $display("Error: MAC Test 8 failed. Expected result=%d, got %d", -24'd16256, $signed(result));
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 11 passed: MAC operation with extreme values (-128*127=-16256), activation passthrough correct");
    end

    // Test case 12: MAC Operation - Large partial sum
    init_inputs();
    weight_mem  = 8'd50;  // Positive weight
    activation  = 8'd50;  // Positive activation
    partial_sum = 24'h7FFFFF;  // Large positive partial sum (close to max 24-bit value)
    #1;

    // Expected: 50 * 50 + 8,388,607 = 8,391,107
    if (result !== 24'd8391107) begin
      $display("Error: MAC Test 9 failed. Expected result=%d, got %d", 24'd8391107, result);
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 12 passed: MAC operation with large partial sum (50*50+8388607=8391107), activation passthrough correct");
    end

    // Test case 13: MAC Operation - Large negative partial sum
    init_inputs();
    weight_mem  = 8'd25;  // Positive weight
    activation  = 8'd25;  // Positive activation
    partial_sum = 24'h800000;  // Large negative partial sum (min 24-bit signed value)
    #1;

    // Expected: 25 * 25 + (-8,388,608) = -8,387,983
    if ($signed(result) !== -24'd8387983) begin
      $display("Error: MAC Test 10 failed. Expected result=%d, got %d", -24'd8387983, $signed(
                                                                                          result));
      errors++;
    end else if (activation_out !== activation) begin
      $display("Error: Expected activation_out=%d, got %d", activation, activation_out);
      errors++;
    end else begin
      $display(
          "Test case 13 passed: MAC operation with large negative partial sum (25*25-8388608=-8387983), activation passthrough correct");
    end

    // Summarize results
    if (errors == 0) $display("All PE_MXU_comb tests passed!");
    else $display("%d PE_MXU_comb tests failed.", errors);

    $display("Testbench completed.");
    $finish;
  end
endmodule
