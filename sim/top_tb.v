// top_tb.v
`timescale 1ns/1ps
module top_tb;
    reg clk = 0;
    reg reset = 1;
    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] alures;

    top_single uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc),
        .instr_out(instr),
        .alu_res_out(alures)
    );

    // clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("rv32i.vcd");
        $dumpvars(0, top_tb);

        // initialize instr_rom and data memory inside uut
        // small program (hand-assembled) example:
        // 0:  LUI x1, 0x10000        -> x1 = 0x10000000 (for data base)
        // 4:  ADDI x2, x0, 5        -> x2 = 5
        // 8:  SW x2, 0(x1)          -> mem[0x10000000] = 5
        // 12: LW x3, 0(x1)          -> x3 = mem[0x10000000]
        // 16: ADD x4, x2, x3        -> x4 = 10
        // 20: BEQ x4, x0, skip      -> (not taken)
        // 24: JAL x0, -4            -> infinite loop if taken
        // 28: HALT (we don't have HALT; we'll just run some cycles)
        // We must write corresponding opcodes (32-bit little-endian words).
        // For demonstration, we put some assembled words (pre-calculated).

        // Fill instruction ROM manually (these machine codes must be correct).
        // For simplicity, set some simple instructions (ADDI & ADD)
        // ADDI x1,x0,1 : opcode 0010011 funct3 000 rd=1 rs1=0 imm=1 => 0x00100093
        uut.instr_rom[0]  = 32'h00100093; // addi x1,x0,1
        uut.instr_rom[1]  = 32'h00200113; // addi x2,x0,2
        uut.instr_rom[2]  = 32'h002081b3; // add x3,x1,x2  (funct7=0, rs2=2, rs1=1, rd=3, opcode=0110011) - assembled manual check
        uut.instr_rom[3]  = 32'h00000013; // nop (addi x0,x0,0)
        uut.instr_rom[4]  = 32'h00000013; // nop
        // rest zeros

        // initialize data memory (dmem.mem) if needed:
        // Example write to data mem via hierarchical reference
        // uut.dmem.mem[0] = 32'h00000005;

        #20 reset = 0;
        #400;
        $display("Simulation finished. PC=%h instr=%h alu_res=%h", pc, instr, alures);
        $finish;
    end

    // simple display on every instruction (posedge)
    always @(posedge clk) begin
        $display("T=%0t PC=%h INSTR=%h ALU=%h", $time, pc, instr, alures);
    end

endmodule
