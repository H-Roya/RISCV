module cpu (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out,     // for debug
    output wire [31:0] instr_out,  // for debug
    output wire [31:0] alu_res_out, // for debug
    output wire [31:0] wb_data_out //for debug
);
    // internal signals
    reg  [31:0] pc;
    wire [31:0] instr;
    wire [31:0] imm;
    wire [31:0] rd1, rd2;
    wire [31:0] alu_b;
    wire [31:0] alu_res;
    wire        eq, lt_signed;

    // control signals
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire [3:0]  alu_op;
    wire        alu_src;
    wire [2:0]  imm_sel;
    wire        branch;
    wire [2:0]  branch_type;
    wire        jal;
    wire        jalr;
    wire        is_lui;

    // writeback temporaries
    reg [31:0] wb_data;
    reg [31:0] rd_from_mem;

    //Instruction ROM (internal program storage)
    reg [31:0] instr_rom [0:1023];

    initial begin
        // Immediate ALU instructions

        instr_rom[0]  = 32'h00500093; // addi x1, x0, 5
        instr_rom[1]  = 32'h00A00113; // addi x2, x0, 10
        instr_rom[2]  = 32'h00308193; // addi x3, x1, 3   (x3 = 8)

        instr_rom[3]  = 32'h0020F213; // andi x4, x1, 2   (5 & 2 = 0)
        instr_rom[4]  = 32'h0020E293; // ori  x5, x1, 2   (5 | 2 = 7)
        instr_rom[5]  = 32'h0030C313; // xori x6, x1, 3   (5 ^ 3 = 6)

        instr_rom[6]  = 32'h00109193; // slli x3, x1, 1   (5 << 1 = 10)
        instr_rom[7]  = 32'h00115213; // srli x4, x2, 1   (10 >> 1 = 5)
        instr_rom[8]  = 32'h40115293; // srai x5, x2, 1   (arith shift)

        instr_rom[9]  = 32'h0020A313; // slti x6, x1, 2   (5 < 2 ? 0)
        instr_rom[10] = 32'h0060B393; // sltiu x7, x1, 6  (5 < 6 ? 1)

        // Register-register ALU ops

        instr_rom[11] = 32'h002081B3; // add  x3, x1, x2  (5 + 10 = 15)
        instr_rom[12] = 32'h40208233; // sub  x4, x1, x2  (5 - 10 = -5)
        instr_rom[13] = 32'h0020F2B3; // and  x5, x1, x2
        instr_rom[14] = 32'h0020E333; // or   x6, x1, x2
        instr_rom[15] = 32'h0020C3B3; // xor  x7, x1, x2

        instr_rom[16] = 32'h00209433; // sll  x8, x1, x2[4:0]
        instr_rom[17] = 32'h0020D4B3; // srl  x9, x1, x2
        instr_rom[18] = 32'h4020D533; // sra  x10, x1, x2

        instr_rom[19] = 32'h0020A5B3; // slt  x11, x1, x2
        instr_rom[20] = 32'h0020B633; // sltu x12, x1, x2

        // Memory operations

        instr_rom[21] = 32'h00312023; // sw x3, 0(x2)   (store 15)
        instr_rom[22] = 32'h00012183; // lw x3, 0(x2)   (load back 15)

        // Branch instructions

        instr_rom[23] = 32'h00208463; // beq x1, x2, +8 (not taken)
        instr_rom[24] = 32'h00100193; // addi x3, x0, 1 (executed)

        instr_rom[25] = 32'h00109463; // bne x1, x1, +8 (not taken)
        instr_rom[26] = 32'h00200193; // addi x3, x0, 2

        instr_rom[27] = 32'h0020C463; // blt x1, x2, +8 (taken)
        instr_rom[28] = 32'h00300193; // addi x3, x0, 3 (skipped)

        instr_rom[29] = 32'h0020D463; // bge x2, x1, +8 (taken)
        instr_rom[30] = 32'h00400193; // addi x3, x0, 4 (skipped)

        // LUI

        instr_rom[31] = 32'h123450B7; // lui x1, 0x12345

        // Jumps

        instr_rom[32] = 32'h004000EF; // jal x1, +4
        instr_rom[33] = 32'h00500113; // addi x2, x0, 5

        // End (infinite loop)

        instr_rom[34] = 32'h0000006F; // jal x0, 0 (halt)
    end

    // fetch
    assign instr = instr_rom[pc[31:2]];

    // register file
    regfile rf (
        .clk(clk),
        .reset(reset),
        .we(reg_write),
        .ra1(instr[19:15]), // rs1
        .ra2(instr[24:20]), // rs2
        .wa(instr[11:7]),   // rd
        .wd( (mem_to_reg) ? rd_from_mem : wb_data ),
        .rd1(rd1),
        .rd2(rd2)
    );

    // control & imm gen
    wire [31:0] imm_wire;
    control ctrl (
        .instr(instr),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .imm_sel(imm_sel),
        .branch(branch),
        .branch_type(branch_type),
        .jal(jal),
        .jalr(jalr),
        .is_lui(is_lui)
    );

    imm_gen ig (
        .instr(instr),
        .imm_sel(imm_sel),
        .imm_out(imm_wire)
    );

    assign imm = imm_wire;

    // data memory instance (for loads/stores)
    wire [31:0] dmem_read_data;
    memory #(.MEM_WORDS(1024)) dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(alu_res),
        .write_data(rd2),
        .read_data(dmem_read_data)
    );

    // ALU input B multiplexer (immediate or rs2)
    assign alu_b = alu_src ? imm : rd2;

    // ALU
    alu alu0 (
        .a(rd1),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_res),
        .eq(eq),
        .lt_signed(lt_signed)
    );

    // Branch decision logic
    wire branch_taken;
    assign branch_taken = branch && (
        (branch_type == 3'd0 && eq)  || // BEQ
        (branch_type == 3'd1 && !eq) || // BNE
        (branch_type == 3'd2 && lt_signed) || // BLT (signed)
        (branch_type == 3'd3 && !lt_signed && !eq) // BGE (signed)
    );

    // Compute next PC
    wire [31:0] pc_next_sequential = pc + 4;
    wire [31:0] pc_branch_target   = pc + imm; // imm for B/J already shifted in imm_gen
    wire [31:0] pc_jalr_target     = (rd1 + imm) & ~32'd1; // low bit = 0
    wire [31:0] pc_next = (jal) ? (pc + imm) :
                          (jalr) ? pc_jalr_target :
                          (branch_taken ? pc_branch_target : pc_next_sequential);

    // Writeback selection
    wire [31:0] wb_from_alu = alu_res;
    wire [31:0] wb_from_mem = dmem_read_data;
    wire [31:0] wb_from_pc4 = pc + 4;
    wire [31:0] wb_from_lui = imm; // imm already shifted << 12

    always @(*) begin
        rd_from_mem = wb_from_mem;
        if (is_lui) wb_data = wb_from_lui;
        else if (mem_to_reg) wb_data = wb_from_mem;
        else if (jal || jalr) wb_data = wb_from_pc4;
        else wb_data = wb_from_alu;
    end

    // PC update (clocked)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'd0;
        end else begin
            pc <= pc_next;
        end
    end

    // drive outputs for debug
    assign pc_out      = pc;
    assign instr_out   = instr;
    assign alu_res_out = alu_res;
    assign wb_data_out = wb_data;

endmodule
