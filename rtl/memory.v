module memory #(
    parameter MEM_WORDS = 1024
)(
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,      // byte address
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] mem [0:MEM_WORDS-1];
    wire [31:0] word_addr = addr[31:2]; // word index

    // aligned reads (combinational read of memory)
    always @(*) begin
        if (mem_read) begin
            read_data = mem[word_addr];
        end else begin
            read_data = 32'd0;
        end
    end

    // writes on clock
    always @(posedge clk) begin
        if (mem_write) begin
            mem[word_addr] <= write_data;
        end
    end

    // simple initializer left to testbench or user; example values can be loaded from TB
endmodule
