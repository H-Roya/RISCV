module cpu (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out,     // for debug
    output wire [31:0] instr_out,  // for debug
    output wire [31:0] alu_res_out // for debug
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

    memory mem0 (
        .clk(clk),
        .mem_read(1'b0),  
        .mem_write(1'b0),
        .addr(32'd0),
        .write_data(32'd0),
        .read_data() // not used
    );

    reg [31:0] instr_rom [0:1023];
    assign instr = instr_rom[pc[31:2]];

    // register file
    regfile rf (
        .clk(clk),
        .reset(reset),
        .we(reg_write),
        .ra1(instr[19:15]), // rs1
        .ra2(instr[24:20]), // rs2
        .wa(instr[11:7]),   // rd
        .wd( (mem_to_reg) ? /*load data from dmem*/ rd_from_mem : wb_data ),
        .rd1(rd1),
        .rd2(rd2)
    );

    // instantiate control and imm_gen
    wire        dummy_reg_write;
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
        (branch_type == 3'd3 && !lt_signed && !eq) // BGE (signed) -> not less
    );

    // Compute next PC
    wire [31:0] pc_next_sequential = pc + 4;
    wire [31:0] pc_branch_target   = pc + imm; // imm for B/J already shifted in imm_gen
    wire [31:0] pc_jalr_target     = (rd1 + imm) & ~32'd1; // low bit = 0
    wire [31:0] pc_next = (jal) ? pc + imm :
                          (jalr) ? pc_jalr_target :
                          (branch_taken ? pc_branch_target : pc_next_sequential);

    // Writeback selection
    wire [31:0] wb_from_alu = alu_res;
    wire [31:0] wb_from_mem = dmem_read_data;
    wire [31:0] wb_from_pc4 = pc + 4;
    wire [31:0] wb_from_lui = imm; // imm already shifted << 12
    reg  [31:0] wb_data;
    reg  [31:0] rd_from_mem;

    always @(*) begin
        rd_from_mem = wb_from_mem;
        if (is_lui) wb_data = wb_from_lui;
        else if (mem_to_reg) wb_data = wb_from_mem;
        else if (jal || jalr) wb_data = wb_from_pc4;
        else wb_data = wb_from_alu;
    end

endmodule
