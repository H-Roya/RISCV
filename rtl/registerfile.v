module regfile (
    input  wire        clk,
    input  wire        reset,
    input  wire        we,       // write enable
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [4:0]  wa,
    input  wire [31:0] wd,
    output reg  [31:0] rd1,
    output reg  [31:0] rd2
);
    reg [31:0] regs [0:31];
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) regs[i] <= 32'd0;
        end else begin
            if (we && (wa != 5'd0))
                regs[wa] <= wd;
        end
    end
    always @(*) begin
        rd1 = (ra1 == 5'd0) ? 32'd0 : regs[ra1];
        rd2 = (ra2 == 5'd0) ? 32'd0 : regs[ra2];
    end
endmodule
