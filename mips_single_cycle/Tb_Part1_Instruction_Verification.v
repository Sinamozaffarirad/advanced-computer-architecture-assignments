`timescale 1ns/1ns

module tb_part1_instruction_verification;
    localparam [5:0] OPCODE_ADDI = 6'b000001,
                     OPCODE_LW   = 6'b000011,
                     OPCODE_BEQ  = 6'b000101,
                     OPCODE_ORI  = 6'b001101,
                     OPCODE_LUI  = 6'b001111;

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
    reg expected_reg_write [0:255];
    reg expected_mem_read [0:255];
    integer expected_next_index [0:255];
    integer instruction_count = 0;
    integer first_check;
    integer index;
    integer checks_run = 0;
    reg [4:0] destination;

    always #5 clk = ~clk;

    // ADDI is already supported by the starter and initializes the test operands.
    task seed_register;
        input [4:0] rt;
        input [15:0] value;
        begin
            dut.DP.InstMem.mem_inst[instruction_count] = {OPCODE_ADDI, 5'd0, rt, value};
            instruction_count = instruction_count + 1;
        end
    endtask

    task expect_writeback;
        input [31:0] instruction;
        input [4:0] dest;
        input mem_read;
        input [31:0] result;
        begin
            dut.DP.InstMem.mem_inst[instruction_count] = instruction;
            expected[instruction_count] = result;
            expected_destination[instruction_count] = dest;
            expected_reg_write[instruction_count] = 1'b1;
            expected_mem_read[instruction_count] = mem_read;
            expected_next_index[instruction_count] = instruction_count + 1;
            instruction_count = instruction_count + 1;
        end
    endtask

    task expect_r_type;
        input [5:0] funct;
        input [4:0] rs, rt, rd, shamt;
        input [31:0] result;
        expect_writeback({6'b000000, rs, rt, rd, shamt, funct}, rd, 1'b0, result);
    endtask

    task expect_i_type;
        input [5:0] opcode;
        input [4:0] rs, rt;
        input [15:0] immediate;
        input [31:0] result;
        expect_writeback({opcode, rs, rt, immediate}, rt, opcode == OPCODE_LW, result);
    endtask

    task expect_beq;
        input [4:0] rs, rt;
        input [15:0] offset;
        input integer next_index;
        begin
            dut.DP.InstMem.mem_inst[instruction_count] = {OPCODE_BEQ, rs, rt, offset};
            expected_reg_write[instruction_count] = 1'b0;
            expected_mem_read[instruction_count] = 1'b0;
            expected_next_index[instruction_count] = next_index;
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
        dut.DP.data_mem.mem_data[7] = 32'h01234567;
        dut.DP.data_mem.mem_data[9] = 32'hFEDCBA98;

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

        expect_i_type(OPCODE_ADDI, 5'd1,  5'd24, 16'h000B, 32'h00000060);
        expect_i_type(OPCODE_ADDI, 5'd24, 5'd25, 16'h8000, 32'hFFFF8060);
        expect_i_type(OPCODE_LUI,  5'd0,  5'd26, 16'hABCD, 32'hABCD0000);
        expect_i_type(OPCODE_ORI,  5'd26, 5'd26, 16'h9234, 32'hABCD9234);
        expect_i_type(OPCODE_ORI,  5'd26, 5'd27, 16'h0000, 32'hABCD9234);
        expect_i_type(OPCODE_LUI,  5'd0,  5'd27, 16'h0000, 32'h00000000);
        expect_i_type(OPCODE_ADDI, 5'd0,  5'd28, 16'h0020, 32'h00000020);
        expect_i_type(OPCODE_LW,   5'd28, 5'd29, 16'h0004, 32'hFEDCBA98);
        expect_i_type(OPCODE_LW,   5'd28, 5'd30, 16'hFFFC, 32'h01234567);

        expect_beq(5'd29, 5'd30, 16'd2, instruction_count + 1);  // Unequal, fall through.
        // Execute the following three branches in the order first, third, second.
        expect_beq(5'd29, 5'd29, 16'd1, instruction_count + 2);
        expect_beq(5'd30, 5'd30, 16'd1, instruction_count + 2);
        expect_beq(5'd29, 5'd29, 16'hFFFE, instruction_count - 1);

        @(negedge clk);
        rst = 0;
        wait (dut.DP.out_pc === 4 * first_check);

        for (index = first_check; index < instruction_count; index = expected_next_index[index]) begin
            @(posedge clk);
            destination = expected_destination[index];
            if ({dut.MemRead, dut.MemWrite} !== {expected_mem_read[index], 1'b0})
                $fatal(1, "Incorrect data memory controls at instruction index %0d", index);
            if (dut.Regwrite !== expected_reg_write[index])
                $fatal(1, "Incorrect register write enable at instruction index %0d", index);
            #1;
            if (dut.DP.out_pc !== 4 * expected_next_index[index])
                $fatal(1, "Instruction index %0d: expected next PC %0d, got %0d",
                       index, 4 * expected_next_index[index], dut.DP.out_pc);
            if (expected_reg_write[index] && dut.DP.RegFile.register[destination] !== expected[index])
                $fatal(1, "Instruction index %0d, r%0d: expected %08h, got %08h",
                       index, destination, expected[index], dut.DP.RegFile.register[destination]);
            checks_run = checks_run + 1;
        end

        $display("PASS: %0d Part 1 instruction checks", checks_run);
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "Timed out waiting for the Part 1 instruction checks");
    end
endmodule
