module memory #(
    parameter MEM_BYTES = 4096   // 4 KB memory
)(
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,        // byte address
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

    reg [7:0] mem [0:MEM_BYTES-1];

    // Read combinationally 32-bit word little-endian
    always @(*) begin
        if (mem_read) begin
            read_data = {
                mem[addr + 3],
                mem[addr + 2],
                mem[addr + 1],
                mem[addr + 0]
            };
        end else begin
            read_data = 32'd0;
        end
    end

    // Write synchronously
    always @(posedge clk) begin
        if (mem_write) begin
            mem[addr + 0] <= write_data[7:0];
            mem[addr + 1] <= write_data[15:8];
            mem[addr + 2] <= write_data[23:16];
            mem[addr + 3] <= write_data[31:24];
        end
    end

    /*integer i;
    initial begin
        for (i = 0; i < MEM_BYTES; i = i + 1)
            mem[i] = 8'd0;
    end*/


endmodule