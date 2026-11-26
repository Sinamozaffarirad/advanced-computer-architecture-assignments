`timescale 1ns/1ns

module tb_highlighted;
    localparam [5:0] FUNC_OR  = 6'b000001,
                     FUNC_SUB = 6'b000011,
                     FUNC_NOR = 6'b000101,
                     FUNC_SLL = 6'b000110,
                     FUNC_SRA = 6'b000111;

    reg clk = 0;
    reg rst = 1;
    mips dut(.clk(clk), .rst(rst), .out1(), .out2());

    reg [31:0] expected [0:255];
    reg [4:0] expected_destination [0:255];
    integer instruction_count = 0;
    integer first_check;
    integer index;
    reg [4:0] destination;

    always #5 clk = ~clk;

    // ADDI is already supported by the starter and initializes the test operands.
    task seed_register;
        input [4:0] rt;
        input [15:0] value;
        begin
            dut.DP.InstMem.mem_inst[instruction_count] = {6'b000001, 5'd0, rt, value};
            instruction_count = instruction_count + 1;
        end
    endtask

    task expect_r_type;
        input [5:0] funct;
        input [4:0] rs, rt, rd, shamt;
        input [31:0] result;
        begin
            dut.DP.InstMem.mem_inst[instruction_count] = {6'b000000, rs, rt, rd, shamt, funct};
            expected[instruction_count] = result;
            expected_destination[instruction_count] = rd;
            instruction_count = instruction_count + 1;
        end
    endtask

    initial begin
        // Load the test after the starter's time-zero memory initialization.
        #1;
        seed_register(5'd1, 16'h0055);
        seed_register(5'd2, 16'h000F);
        seed_register(5'd3, 16'hFFF8);  // -8
        seed_register(5'd4, 16'h0001);
        seed_register(5'd5, 16'hFFFF);  // -1
        seed_register(5'd10, 16'h0001);
        seed_register(5'd14, 16'h0001);
        seed_register(5'd18, 16'h0001);

        first_check = instruction_count;
        expect_r_type(FUNC_SUB, 5'd1,  5'd2,  5'd8,  5'd0,  32'h00000046);
        expect_r_type(FUNC_SUB, 5'd2,  5'd1,  5'd9,  5'd0,  32'hFFFFFFBA);
        expect_r_type(FUNC_SUB, 5'd3,  5'd3,  5'd10, 5'd0,  32'h00000000);
        expect_r_type(FUNC_OR,  5'd1,  5'd2,  5'd11, 5'd0,  32'h0000005F);
        expect_r_type(FUNC_OR,  5'd0,  5'd3,  5'd12, 5'd0,  32'hFFFFFFF8);
        expect_r_type(FUNC_NOR, 5'd1,  5'd2,  5'd13, 5'd0,  32'hFFFFFFA0);
        expect_r_type(FUNC_NOR, 5'd5,  5'd2,  5'd14, 5'd0,  32'h00000000);
        expect_r_type(FUNC_SLL, 5'd0,  5'd2,  5'd15, 5'd4,  32'h000000F0);
        expect_r_type(FUNC_SLL, 5'd0,  5'd1,  5'd16, 5'd0,  32'h00000055);
        expect_r_type(FUNC_SLL, 5'd0,  5'd4,  5'd17, 5'd31, 32'h80000000);
        expect_r_type(FUNC_SLL, 5'd0,  5'd17, 5'd18, 5'd1,  32'h00000000);
        expect_r_type(FUNC_SRA, 5'd0,  5'd3,  5'd19, 5'd2,  32'hFFFFFFFE);
        expect_r_type(FUNC_SRA, 5'd0,  5'd1,  5'd20, 5'd2,  32'h00000015);
        expect_r_type(FUNC_SRA, 5'd0,  5'd3,  5'd21, 5'd0,  32'hFFFFFFF8);
        expect_r_type(FUNC_SRA, 5'd0,  5'd17, 5'd22, 5'd31, 32'hFFFFFFFF);
        // Same source and destination fields as above, with only shamt changed.
        expect_r_type(FUNC_SRA, 5'd0,  5'd17, 5'd22, 5'd30, 32'hFFFFFFFE);
        // The starter stores the low 32 bits of subtraction.
        expect_r_type(FUNC_SUB, 5'd17, 5'd4,  5'd23, 5'd0,  32'h7FFFFFFF);

        @(negedge clk);
        rst = 0;
        wait (dut.DP.out_pc === 4 * first_check);

        for (index = first_check; index < instruction_count; index = index + 1) begin
            @(posedge clk);
            destination = expected_destination[index];
            if ({dut.MemRead, dut.MemWrite} !== 2'b00)
                $fatal(1, "Unexpected data memory access at instruction index %0d", index);
            #1;
            if (dut.DP.out_pc !== 4 * (index + 1))
                $fatal(1, "Instruction index %0d: expected next PC %0d, got %0d",
                       index, 4 * (index + 1), dut.DP.out_pc);
            if (dut.DP.RegFile.register[destination] !== expected[index])
                $fatal(1, "Instruction index %0d, r%0d: expected %08h, got %08h",
                       index, destination, expected[index], dut.DP.RegFile.register[destination]);
        end

        $display("PASS: %0d highlighted R-type instruction checks", instruction_count - first_check);
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "Timed out waiting for the highlighted instruction checks");
    end
endmodule
