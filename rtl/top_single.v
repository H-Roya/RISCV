module top_single (
    input  wire clk,
    input  wire reset,
    output wire [31:0] pc_out,
    output wire [31:0] instr_out,
    output wire [31:0] alu_res_out
);
    // PC
    reg [31:0] pc;

    // Instruction ROM (word addressed)
    reg [31:0] instr_rom [0:1023];
    wire [31:0] instr = instr_rom[pc[31:2]];

    // Control / imm
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

    wire [31:0] imm;
    imm_gen ig (.instr(instr), .imm_sel(imm_sel), .imm_out(imm));

    // Register file wires
    wire [31:0] rd1, rd2;
    wire [4:0]  rs1 = instr[19:15];
    wire [4:0]  rs2 = instr[24:20];
    wire [4:0]  rd  = instr[11:7];

    regfile rf (
        .clk(clk),
        .reset(reset),
        .we(reg_write),
        .ra1(rs1),
        .ra2(rs2),
        .wa(rd),
        .wd( /* driven below */ wb_data ),
        .rd1(rd1),
        .rd2(rd2)
    );

    // Data memory (separate instance)
    wire [31:0] dmem_rdata;
    wire [31:0] alu_b = alu_src ? imm : rd2;

    // ALU
    wire [31:0] alu_res;
    wire eq, lt_signed;
    alu myalu (.a(rd1), .b(alu_b), .alu_op(alu_op), .result(alu_res), .eq(eq), .lt_signed(lt_signed));

    memory #(.MEM_WORDS(1024)) dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(alu_res),
        .write_data(rd2),
        .read_data(dmem_rdata)
    );

    // Branch decision
    wire branch_taken = branch && (
        (branch_type == 3'd0 && eq)  || // BEQ
        (branch_type == 3'd1 && !eq) || // BNE
        (branch_type == 3'd2 && lt_signed) || // BLT
        (branch_type == 3'd3 && !lt_signed && !eq) // BGE
    );

    // PC next
    wire [31:0] pc_plus4 = pc + 4;
    wire [31:0] pc_branch = pc + imm;
    wire [31:0] pc_jalr = (rd1 + imm) & ~32'd1;
    wire [31:0] pc_next = (jal) ? pc + imm :
                          (jalr) ? pc_jalr :
                          (branch_taken ? pc_branch : pc_plus4);

    // writeback selection
    reg [31:0] wb_data;
    always @(*) begin
        if (is_lui) wb_data = imm;
        else if (mem_to_reg) wb_data = dmem_rdata;
        else if (jal || jalr) wb_data = pc_plus4;
        else wb_data = alu_res;
    end

    // Hook output signals for debug
    assign pc_out = pc;
    assign instr_out = instr;
    assign alu_res_out = alu_res;

    // PC and reset logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'd0;
            // Optionally zero-initialize instr_rom and dmem in TB
        end else begin
            pc <= pc_next;
        end
    end

    // Expose instr_rom and data mem initialization to TB via hierarchical referencing
    // (In TB we'll write to top_single.instr_rom and top_single.<dmem internal name> if needed)
endmodule
