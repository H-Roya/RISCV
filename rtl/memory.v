`timescale 1ns / 1ps

module memory (
    input  wire [7:0] addr,
    output reg  [7:0] data_out
);

    reg [7:0] mem [0:255];

    //add testing
    /*initial begin
        mem[0] = 8'b00010001; // LDI R0, 1
        mem[1] = 8'b00010101; // LDI R1, 5
        mem[2] = 8'b00100001; // ADD R0, R1
        mem[3] = 8'b11110000; // HALT
    end*/

    //branch testing doesn't branch
    /*initial begin
        mem[0] = 8'b00010010; // LDI R0, 2
        mem[1] = 8'b00010100; // LDI R1, 4
        mem[2] = 8'b00100001; // ADD R0, R1 -> R0 = 6
        mem[3] = 8'b00110001; // SUB R0, R1 -> R0 = 2
        mem[4] = 8'b01010010; // BRZ 2 (should not branch)
        mem[5] = 8'b00011011; // LDI R2, 3
        mem[6] = 8'b00011100; // LDI R3, 4
        mem[7] = 8'b01010100; // BRZ 4 (should not branch)
        mem[8] = 8'b11110000; // HALT
    end*/

    //jump testing
    /*initial begin
        mem[0] = 8'b01000010; // JMP 2
        mem[1] = 8'b00010001; // LDI R0, 1 (should be skipped)
        mem[2] = 8'b00010011; // LDI R0, 3
        mem[3] = 8'b11110000; // HALT
    end*/

    //brz test branches
    /*initial begin
        mem[0] = 8'b00010000; // LDI R0, 0
        mem[1] = 8'b01010010; // BRZ 2 (should branch to PC=2)
        mem[2] = 8'b00010011; // LDI R0, 3
        mem[3] = 8'b11110000; // HALT

    end*/

    //final test1:
    /*initial begin
        mem[0] = 8'b00010010; // LDI R0, 2
        mem[1] = 8'b01010011; // BRZ 3 (should not branch, R0 ≠ 0)
        mem[2] = 8'b00010100; // LDI R1, 4 (should execute)
        mem[3] = 8'b11110000; // HALT
    end*/

    //final test2:
    /*initial begin
        mem[0] = 8'b00010011; // LDI R0, 3
        mem[1] = 8'b00110000; // SUB R0, R0 -> R0 = 0
        mem[2] = 8'b01010011; // BRZ 3 (if zero, branch to HALT)
        mem[3] = 8'b11110000; // HALT
        mem[4] = 8'b01000001; // JMP 1 (loop back to SUB)
    end*/

    //final test3: AND OR doesn't work. Add the opcodes.
    /*initial begin
        mem[0] = 8'b00010010; // LDI R0, 2  (0010)
        mem[1] = 8'b00010101; // LDI R1, 5  (0101)
        mem[2] = 8'b01100001; // AND R0, R1 -> 0000
        //mem[2] = 8'b01110001; // OR R0, R1 -> 0111
        mem[3] = 8'b11110000; // HALT
    end*/

    /*initial begin
        mem[0] = 8'b00010010; // LDI R0, 2  -> R0 = 0010
        mem[1] = 8'b00010101; // LDI R1, 5  -> R1 = 0101
        mem[2] = 8'b01110001; // OR R0, R1 -> 0010 | 0101 = 0111
        mem[3] = 8'b11110000; // HALT
    end*/

    //STL, NOT test
    /*initial begin
        mem[0] = 8'b00010001; // LDI R0, 1
        mem[1] = 8'b00010100; // LDI R1, 4
        mem[2] = 8'b10010001; // SLT R0, R1 -> R0 < R1 -> R0 = 1
        mem[3] = 8'b10000000; // NOT R0 -> ~00000001 = 11111110
        mem[4] = 8'b11110000; // HALT
    end*/

    //Shift test
    /*initial begin
        mem[0] = 8'b00010001; // LDI R0, 1   (00000001)
        mem[1] = 8'b10100000; // SHL R0      -> 00000010
        mem[2] = 8'b10110000; // SHR R0      -> 00000001
        mem[3] = 8'b11110000; // HALT
    end*/

    //Flag test
    /*initial begin
        mem[0] = 8'b00010000; // LDI R0, 0
        mem[1] = 8'b00110000; // SUB R0, R0 (result 0 -> Z=1)
        mem[2] = 8'b00010001; // LDI R0, 1
        mem[3] = 8'b00110000; // SUB R0, R0 (result 0 -> Z=1)
        mem[4] = 8'b11110000; // HALT
    end*/

    //N/C flag test
    /*initial begin
        mem[0] = 8'b00010001; // LDI R0, 1       ; R0 = 1
        mem[1] = 8'b00010111; // LDI R1, 7       ; R1 = 7
        mem[2] = 8'b00110000; // SUB R0, R0      ; R0 - R0 = 0 → Z=1, N=0, C=0
        mem[3] = 8'b00110001; // SUB R0, R1      ; 0 - 7 = 249 → Z=0, N=1, C=1
        mem[4] = 8'b00011111; // LDI R3, 255     ; R3 = 255
        mem[5] = 8'b00100011; // ADD R3, R0      ; 255 + 249 = overflow → Z=?, N=?, C=1
        mem[6] = 8'b11110000; // HALT
    end*/

    //Test for BRN doesn't jump
    /*initial begin
        mem[0] = 8'b00010001; // LDI R0, 1
        mem[1] = 8'b00110000; // SUB R0, R0
        mem[2] = 8'b11000011; // BRN to address 3 (won't branch, N=0)
        mem[3] = 8'b00111100; // SUB R0, R0 (again, Z=1)
        mem[4] = 8'b11110000; // HALT
    end*/

    //Test for BRN jumps
    /*initial begin
        mem[0] = 8'b00010000; // LDI R0, 0
        mem[1] = 8'b00010111; // LDI R1, 7
        mem[2] = 8'b00110001; // SUB R0, R1  => 0 - 7 = negative
        mem[3] = 8'b11000101; // BRN 5 => should jump to 5
        mem[4] = 8'b11110000; // HALT (should be skipped)
        mem[5] = 8'b00010100; // LDI R1, 4 (should run if BRN worked)
        mem[6] = 8'b11110000; // HALT
    end*/

    //Test for BRC
    initial begin
        mem[0] = 8'b00010001; // LDI R0, 1
        mem[1] = 8'b00010111; // LDI R1, 7
        mem[2] = 8'b00110000; // SUB R0, R0 => 0, Z=1
        mem[3] = 8'b00111100; // SUB R0, R0 => 0, Z=1
        mem[4] = 8'b00011111; // SUB R0, R7 => 0 - 15 => N=1, C=1
        mem[5] = 8'b11010110; // BRC 6 => should jump here due to carry
        mem[6] = 8'b11110000; // HALT (should be executed if branch worked)
        mem[7] = 8'b00010011; // LDI R0, 3 (should be skipped)
    end

    /*initial begin
        mem[0] = 8'b00010001; // LDI R0, 1
        mem[1] = 8'b00010111; // LDI R1, 7
        mem[2] = 8'b00110000; // SUB R0, R0  => Z bayrağı set olur
        mem[3] = 8'b10011100; // SLT R0, R1
        mem[4] = 8'b10001111; // NOT R0
        mem[5] = 8'b11010110; // BRC 6 (eğer Carry set ise 6'ya zıpla)
        mem[6] = 8'b11110000; // HALT

    end*/


    always @(*) begin
        data_out = mem[addr];
    end

endmodule
