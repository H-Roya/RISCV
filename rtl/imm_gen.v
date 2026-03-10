module imm_gen (
    input  wire [31:0] instr,
    input  wire [2:0]  imm_sel, //0=I,1=S,2=B,3=U,4=J
    output reg  [31:0] imm_out
);
    always @(*) begin
        case (imm_sel)
            3'd0: begin //I-type
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end
            3'd1: begin //S-type (store)
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            3'd2: begin //B-type (branch) imm[12|10:5|4:1|11] << 1
                imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            3'd3: begin //U-type (lui/auipc): imm[31:12] << 12
                imm_out = {instr[31:12], 12'b0};
            end
            3'd4: begin //J-type (jal)
                imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            default: imm_out = 32'd0;
        endcase
    end
endmodule