module alu(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,   //encoded ALU operation
    output reg  [31:0] result,
    output wire        eq,       //a == b
    output wire        lt_signed //a < b (signed)
);

    localparam OP_ADD  = 4'h0;
    localparam OP_SUB  = 4'h1;
    localparam OP_AND  = 4'h2;
    localparam OP_OR   = 4'h3;
    localparam OP_XOR  = 4'h4;
    localparam OP_SLL  = 4'h5;
    localparam OP_SRL  = 4'h6;
    localparam OP_SRA  = 4'h7;
    localparam OP_SLT  = 4'h8; //signed set less than
    localparam OP_SLTU = 4'h9; //unsigned set less than

    always @(*) begin
        case (alu_op)
            OP_ADD:  result = a + b;
            OP_SUB:  result = a - b;
            OP_AND:  result = a & b;
            OP_OR:   result = a | b;
            OP_XOR:  result = a ^ b;
            OP_SLL:  result = a << b[4:0];
            OP_SRL:  result = a >> b[4:0];
            OP_SRA:  result = $signed(a) >>> b[4:0];
            OP_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            OP_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            default: result = 32'd0;
        endcase
    end

    assign eq = (a == b);
    assign lt_signed = ($signed(a) < $signed(b));

endmodule
