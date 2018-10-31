//-----------------------------------------------------
// Design Name : sync_shfifo
// File Name   : sync_shfifo.v
// Description : Synchronous Show Ahead FIFO
// Coder       : Patrick Liu
// Date        : 2018/10/03
//-----------------------------------------------------
module sync_shfifo #(
    parameter FIFO_WIDTH = 32,
    parameter FIFO_ADDR  = 3,
    parameter FIFO_DEPTH = 1 << FIFO_ADDR,
    parameter FIFO_AE_THRESHOLD = 1,
    parameter FIFO_AF_THRESHOLD = FIFO_DEPTH -1) 
(
    input                           clk,
    input                           rst_n,
    input                           fifo_wen,
    input      [FIFO_WIDTH-1 :0]    fifo_wdat,
    input                           fifo_ren,
    output     [FIFO_WIDTH-1 :0]    fifo_rdat,
    output                          fifo_empty,
    output                          fifo_full,
    output                          fifo_aempty,
    output                          fifo_afull,
    output reg [FIFO_ADDR :0]       fifo_wcnt,
    output reg [FIFO_ADDR :0]       fifo_rcnt,
    output reg                      fifo_wr_full_err,
    output reg                      fifo_rd_empty_err
);

reg  [FIFO_WIDTH-1 :0]   fifo_data[FIFO_DEPTH];
reg  [FIFO_ADDR-1 :0]    fifo_wr_ptr;
reg  [FIFO_ADDR-1 :0]    fifo_rd_ptr;


always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        fifo_wr_ptr <= 'b0;
    end
    else if(fifo_wen & ~fifo_full) begin
        fifo_wr_ptr <= fifo_wr_ptr + 'b1;
    end
    else;
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        for(int i = 0; i <= FIFO_DEPTH-1; i++) begin
            fifo_data[i] <= 'b0;
        end
    end
    else if(fifo_wen & ~fifo_full) begin
        fifo_data[fifo_wr_ptr] <= fifo_wdat;
    end
    else;
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        fifo_rd_ptr <= 'b0;
    end
    else if(fifo_ren & ~fifo_empty) begin
        fifo_rd_ptr <= fifo_rd_ptr + 'b1;
    end
    else;
end

assign fifo_rdat = fifo_data[fifo_rd_ptr];

always@(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        fifo_rcnt <= 'b0;
    end
    else if(fifo_wen & ~fifo_ren & ~fifo_full) begin
        fifo_rcnt <= fifo_rcnt + 'b1;
    end
    else if(fifo_ren & ~fifo_wen & ~fifo_empty) begin
        fifo_rcnt <= fifo_rcnt - 'b1;
    end
    else;
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        fifo_wcnt <= FIFO_DEPTH;
    end
    else if(fifo_wen & ~fifo_ren & ~fifo_full) begin
        fifo_wcnt <= fifo_wcnt - 'b1;
    end
    else if(fifo_ren & ~fifo_wen & ~fifo_empty) begin
        fifo_wcnt <= fifo_wcnt + 'b1;
    end
    else;
end

assign fifo_full = fifo_rcnt == FIFO_DEPTH;
assign fifo_empty = fifo_rcnt == 'b0;
assign fifo_aempty = fifo_rcnt <= FIFO_AE_THRESHOLD;
assign fifo_afull = fifo_rcnt >= FIFO_AF_THRESHOLD;


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        fifo_wr_full_err <= 'b0;
    end
    else if(fifo_full & fifo_wen) begin
        fifo_wr_full_err <= 'b1;
    end
    else;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        fifo_rd_empty_err <= 'b0;
    end
    else if(fifo_empty & fifo_ren) begin
        fifo_rd_empty_err <= 'b1;
    end
    else;
end

endmodule
