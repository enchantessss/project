//-----------------------------------------------------
// Design Name : sdp_ram
// File Name   : sdp_ram.v
// Description : Simple Dual Port Ram, one port read and one port write.
// Coder       : Patrick Liu
// Date        : 2018/10/28
//-----------------------------------------------------
module sdp_ram #(
    parameter RAM_DATA_WIDTH = 32,
    parameter RAM_ADDR_WIDTH = 3,
    parameter RAM_DEPTH = 1 << RAM_ADDR_WIDTH) 
(
    input                                     clk,
    input                                     wen,
    input       [RAM_ADDR_WIDTH-1 : 0]        waddr,
    input       [RAM_DATA_WIDTH-1 : 0]        wdat,
    input                                     ren,
    input       [RAM_ADDR_WIDTH-1 : 0]        raddr,
    output reg  [RAM_DATA_WIDTH-1 : 0]        q  
);

reg wr_en;
reg [RAM_ADDR_WIDTH-1 : 0] wr_addr;
reg [RAM_DATA_WIDTH-1 : 0] wr_data;
reg rd_en;
reg [RAM_ADDR_WIDTH-1 : 0] rd_addr;

always @(posedge clk) begin
    wr_en <= wen;
    wr_addr <= waddr;
    wr_data <= wdat;
    rd_en <= ren;
    rd_addr <= raddr;
end

reg [RAM_DATA_WIDTH-1 : 0] memory[0:RAM_DEPTH-1];

always @(posedge clk) begin
    if(wr_en) begin
        memory[wr_addr] <= wr_data;
    end
    else;
end

always @(posedge clk) begin
    if(rd_en) begin
        q <= memory[rd_addr];
    end
    else;
end

endmodule


