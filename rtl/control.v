module control (
    input  wire [31:0] instr,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg, // 1 => load result goes to regfile
    output reg [3:0]   alu_op,
    output reg         alu_src,    // 1 => use immediate as ALU b
    output reg [2:0]   imm_sel,    // immediate type for imm_gen
    output reg         branch,     // branch instruction
    output reg [2:0]   branch_type, // encodes BEQ/BNE/BLT/BGE 
    output reg         jal,
    output reg         jalr,
    output reg         is_lui,
    output reg         is_auipc,
    output reg [2:0]   load_type
);
    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    localparam BEQ  = 3'd0;
    localparam BNE  = 3'd1;
    localparam BLT  = 3'd2;
    localparam BGE  = 3'd3;
    localparam BLTU = 3'd4;
    localparam BGEU = 3'd5;

    // ALU op encoding must match alu.v
    localparam OP_ADD  = 4'h0;
    localparam OP_SUB  = 4'h1;
    localparam OP_AND  = 4'h2;
    localparam OP_OR   = 4'h3;
    localparam OP_XOR  = 4'h4;
    localparam OP_SLL  = 4'h5;
    localparam OP_SRL  = 4'h6;
    localparam OP_SRA  = 4'h7;
    localparam OP_SLT  = 4'h8;
    localparam OP_SLTU = 4'h9;

    localparam LOAD_LB  = 3'd0;
    localparam LOAD_LH  = 3'd1;
    localparam LOAD_LW  = 3'd2;
    localparam LOAD_LBU = 3'd3;
    localparam LOAD_LHU = 3'd4;

    always @(*) begin
        // defaults
        reg_write  = 0;
        mem_read   = 0;
        mem_write  = 0;
        mem_to_reg = 0;
        alu_op     = OP_ADD;
        alu_src    = 0;
        imm_sel    = 3'd0;
        branch     = 0;
        branch_type= 3'd0;
        jal        = 0;
        jalr       = 0;
        is_lui     = 0;
        is_auipc   = 0;
        load_type  = LOAD_LW;   

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1;
                alu_src   = 0;
                imm_sel   = 3'd0;
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_op = OP_ADD; // ADD
                    {7'b0100000, 3'b000}: alu_op = OP_SUB; // SUB
                    {7'b0000000, 3'b111}: alu_op = OP_AND; // AND
                    {7'b0000000, 3'b110}: alu_op = OP_OR;  // OR
                    {7'b0000000, 3'b100}: alu_op = OP_XOR; // XOR
                    {7'b0000000, 3'b001}: alu_op = OP_SLL; // SLL
                    {7'b0000000, 3'b101}: alu_op = OP_SRL; // SRL
                    {7'b0100000, 3'b101}: alu_op = OP_SRA; // SRA
                    {7'b0000000, 3'b010}: alu_op = OP_SLT; // SLT
                    {7'b0000000, 3'b011}: alu_op = OP_SLTU; // SLTU
                    default: alu_op = OP_ADD;
                endcase
            end
            7'b0010011: begin // I-type ALU (ADDI, SLLI, SRLI, SRAI, ANDI, ORI, XORI, SLTI, SLTIU)
                reg_write = 1;
                alu_src   = 1;
                imm_sel   = 3'd0; // I-type
                case (funct3)
                    3'b000: alu_op = OP_ADD; // ADDI
                    3'b111: alu_op = OP_AND; // ANDI
                    3'b110: alu_op = OP_OR;  // ORI
                    3'b100: alu_op = OP_XOR; // XORI
                    3'b001: alu_op = OP_SLL; // SLLI
                    3'b101: begin            // SRLI/SRAI
                        if (funct7[5] == 1'b0) alu_op = OP_SRL; else alu_op = OP_SRA;
                    end
                    3'b010: alu_op = OP_SLT; // SLTI
                    3'b011: alu_op = OP_SLTU; // SLTIU
                    default: alu_op = OP_ADD;
                endcase
            end
            7'b0000011: begin // LW
                reg_write  = 1;
                mem_read   = 1;
                mem_to_reg = 1;
                alu_src    = 1;
                imm_sel    = 3'd0; // I-type
                alu_op     = OP_ADD; // address = rs1 + imm

                case (funct3)
                    3'b000: load_type = LOAD_LB;  // LB
                    3'b001: load_type = LOAD_LH;  // LH
                    3'b010: load_type = LOAD_LW;  // LW
                    3'b100: load_type = LOAD_LBU; // LBU
                    3'b101: load_type = LOAD_LHU; // LHU
                    default: load_type = LOAD_LW;
                endcase
            end
            7'b0100011: begin // SW
                mem_write = 1;
                alu_src   = 1;
                imm_sel   = 3'd1; // S-type
                alu_op    = OP_ADD; // address = rs1 + imm
            end
            7'b1100011: begin // B-type (branches)
                branch = 1;
                imm_sel = 3'd2; // B-type
                // branch_type chosen by funct3
                case (funct3)
                    3'b000: branch_type = BEQ;
                    3'b001: branch_type = BNE;
                    3'b100: branch_type = BLT;
                    3'b101: branch_type = BGE;
                    3'b110: branch_type = BLTU;
                    3'b111: branch_type = BGEU;
                    default: branch_type = BEQ;
                endcase
                // for branches using ALU subtract and comparators
                //alu_op = OP_SUB;
                alu_op = OP_ADD;
            end
            7'b1101111: begin // JAL
                reg_write = 1;
                jal       = 1;
                imm_sel   = 3'd4; // J-type
            end
            7'b1100111: begin // JALR (I-type)
                reg_write = 1;
                jalr      = 1;
                alu_src   = 1;
                imm_sel   = 3'd0; // I-type
                alu_op    = OP_ADD; // target = rs1 + imm
            end
            7'b0110111: begin // LUI
                reg_write = 1;
                is_lui    = 1;
                imm_sel   = 3'd3; // U-type
            end
            7'b0010111: begin // AUIPC
                reg_write = 1;
                is_auipc  = 1;
                imm_sel   = 3'd3; // U-type
            end
            default: begin
                // unknown => NOP
            end
        endcase
    end
endmodule
