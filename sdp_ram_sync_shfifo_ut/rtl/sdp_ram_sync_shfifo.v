//-----------------------------------------------------
// Design Name : sdp_ram_sync_shfifo
// File Name   : sdp_ram_sync_shfifo.v
// Description : Simple Dual Port Ram Control To Implement FIFO
// Coder       : Patrick Liu
// Date        : 2018/10/28
//-----------------------------------------------------
module sdp_ram_sync_shfifo #(
    parameter FIFO_WIDTH = 32,
    parameter FIFO_ADDR  = 3,
    parameter FIFO_DEPTH = 1 << FIFO_ADDR,
    parameter FIFO_AE_THRESHOLD = 1,
    parameter FIFO_AF_THRESHOLD = FIFO_DEPTH -1,

    parameter RAM_DATA_WIDTH = FIFO_WIDTH,
    parameter RAM_ECC_WIDTH = 0, // RSV
    parameter RAM_ADDR_WIDTH = FIFO_ADDR,
    parameter RAM_DEPTH = 1 << RAM_ADDR_WIDTH) 

(
    input                                                   clk,
    input                                                   rst_n,
    // I/F With FIFO
    input                                                   fifo_wen,
    input      [FIFO_WIDTH - 1 : 0]                         fifo_wdat,
    input                                                   fifo_ren,
    output     [FIFO_WIDTH - 1 : 0]                         fifo_rdat,
    output                                                  fifo_empty,
    output                                                  fifo_full,
    output                                                  fifo_aempty,
    output                                                  fifo_afull,
    output reg [FIFO_ADDR :0]                               fifo_wcnt,
    output reg [FIFO_ADDR :0]                               fifo_rcnt,
    output reg                                              fifo_wr_full_err,
    output reg                                              fifo_rd_empty_err
);

// cache priority: r0 > r1 > ram.
// 
// write -> r0 -> r1 -> r2 :
//     1: if r0 is available, write r0 first;
//     2: if r0 is taken, write r1 then;
//     3: if r1 is also taken, write r2 then;
//     4: if r2 is also taken, write ram then;
// 
// read <- r0 <- r1 <- r2 <- ram :
//     1: if r0 is valid, read r0, r1 shift to r0 if r1 valid;
//     2: r1 always shift to r0;
//     3: r2 alwyas shift to r1;
//     4: ram always pop out to r2;(NA)
//     5: if read occur, and no new write, always read ram if ram has data;
//     6: if read occur, and have new write, if r1 is invalid, & r 2 is valid, & ram empty, data will be write to r2
//     7: ram pop data out, if r0/r1/r2 is invalid, ram data out will skip r2/r1 direct to r0, 
//        or skip r2 direct to r1.(skip to the frontest principle)

reg                                                 ram_wen;
reg   [RAM_ADDR_WIDTH - 1 : 0]                      ram_waddr;
reg   [RAM_DATA_WIDTH + RAM_ECC_WIDTH -1 : 0]       ram_wdat;
reg                                                 ram_ren;
reg   [RAM_ADDR_WIDTH - 1 : 0]                      ram_raddr;
wire  [RAM_DATA_WIDTH - 1 : 0]                      ram_q; 

reg   [FIFO_WIDTH - 1 : 0]                          r0;
reg                                                 r0_vld;
reg   [FIFO_WIDTH - 1 : 0]                          r1;
reg                                                 r1_vld;
reg   [FIFO_WIDTH - 1 : 0]                          r2;
reg                                                 r2_vld;
reg   [FIFO_WIDTH - 1 : 0]                          r3;
reg                                                 r3_vld;
reg   [FIFO_WIDTH - 1 : 0]                          r4;
reg                                                 r4_vld;

reg   [RAM_DATA_WIDTH - 1 : 0]                      stdby_dat; // Ram read data out stdby.
reg                                                 stdby_vld; // Ram_ren_2d

reg   [RAM_ADDR_WIDTH - 1 : 0]                      ram_rcnt;
reg   [RAM_ADDR_WIDTH - 1 : 0]                      ram_rcnt_1d;
reg   [RAM_ADDR_WIDTH - 1 : 0]                      ram_rcnt_2d;
reg                                                 ram_full;
reg                                                 ram_ren_1d;
reg                                                 ram_ren_2d;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        r0 <= 'b0;
        r0_vld <= 'b0;
    end
    else if(~r0_vld & fifo_wen) begin
        r0 <= fifo_wdat;
        r0_vld <= 1'b1;
    end
    else if(r0_vld & fifo_ren) begin
        r0 <= r1_vld ? r1 : r2_vld ? r2 : r3_vld ? r3 : r4_vld ? r4 : stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd1) ? fifo_wdat : 'b0;
        r0_vld <= r1_vld | r2_vld | r3_vld | r4_vld | stdby_vld | (fifo_wen & fifo_rcnt == 'd1);
    end
    else;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        r1 <= 'b0;
        r1_vld <= 'b0;
    end
    else if(r0_vld & ~r1_vld & ~fifo_ren) begin
        r1 <= r2_vld ? r2 : r3_vld ? r3 : r4_vld ? r4 : stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd1) ? fifo_wdat : 'b0;
        r1_vld <= r2_vld | r3_vld | r4_vld | stdby_vld | (fifo_wen & fifo_rcnt == 'd1);
    end
    else if(r1_vld & fifo_ren) begin
        r1 <= r2_vld ? r2 : r3_vld ? r3 : r4_vld ? r4 : stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd2 & r0_vld) ? fifo_wdat :'b0;
        r1_vld <= r2_vld | r3_vld | r4_vld | stdby_vld | (fifo_wen & fifo_rcnt == 'd2 & r0_vld);
    end
    else;
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        r2 <= 'b0;
        r2_vld <= 'b0;
    end
    else if(r0_vld & r1_vld & ~r2_vld & ~fifo_ren) begin
        r2 <= r3_vld ? r3 : r4_vld ? r4 : stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd2) ? fifo_wdat : 'b0;
        r2_vld <= r3_vld | r4_vld | stdby_vld | (fifo_wen & fifo_rcnt == 'd2);
    end
    else if(r2_vld & fifo_ren) begin
        r2 <= r3_vld ? r3 : r4_vld ? r4 : stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd3 & r0_vld & r1_vld) ? fifo_wdat : 'b0;
        r2_vld <= r3_vld | r4_vld | stdby_vld | (fifo_wen & fifo_rcnt == 'd3 & r0_vld & r1_vld);
    end
    else;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        r3 <= 'b0;
        r3_vld <= 'b0;
    end
    else if(r0_vld & r1_vld & r2_vld & ~r3_vld & ~fifo_ren) begin
        r3 <= r4_vld ? r4 : stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd3) ? fifo_wdat : 'b0;
        r3_vld <= r4_vld | stdby_vld | (fifo_wen & fifo_rcnt == 'd3);
    end
    else if(r3_vld & fifo_ren) begin
        r3 <= r4_vld ? r4 : stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd4 & r0_vld & r1_vld & r2_vld) ? fifo_wdat : 'b0;
        r3_vld <= r4_vld | stdby_vld | (fifo_wen & fifo_rcnt == 'd4 & r0_vld & r1_vld & r2_vld);
    end
    else;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        r4 <= 'b0;
        r4_vld <= 'b0;
    end
    else if(r0_vld & r1_vld & r2_vld & r3_vld & ~r4_vld & ~fifo_ren) begin
        r4 <= stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd4) ? fifo_wdat : 'b0;
        r4_vld <= stdby_vld | (fifo_wen & fifo_rcnt == 'd4);
    end
    else if(r4_vld & fifo_ren) begin
        r4 <= stdby_vld ? stdby_dat : (fifo_wen & fifo_rcnt == 'd5 & r0_vld & r1_vld & r2_vld & r3_vld) ? fifo_wdat : 'b0;
        r4_vld <= stdby_vld | (fifo_wen & fifo_rcnt == 'd5 & r0_vld & r1_vld & r2_vld & r3_vld);
    end
    else;
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        ram_wen <= 'b0;
        ram_waddr <= 'b0;
        ram_wdat <= 'b0;
    end
    else if(r0_vld & r1_vld & r2_vld & r3_vld & r4_vld & fifo_wen & ~fifo_ren) begin
        ram_wen <= 'b1;
        ram_waddr <= ram_waddr + ram_wen;
        ram_wdat <= fifo_wdat;
    end
    else if((ram_rcnt != 0 | ram_rcnt_1d != 0 | ram_rcnt_2d != 0) & fifo_wen & ~ram_full) begin
        ram_wen <= 'b1;
        ram_waddr <= ram_waddr + ram_wen;
        ram_wdat <= fifo_wdat;
    end
    else begin
        ram_wen <= 'b0;
        ram_waddr <= ram_waddr + ram_wen;
        ram_wdat <= 'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        ram_rcnt <= 'b0;
        ram_rcnt_1d <= 'b0;
        ram_rcnt_2d <= 'b0;
    end
    else begin
        ram_rcnt <= ram_rcnt + ram_wen - ram_ren;
        ram_rcnt_1d <= ram_rcnt;
        ram_rcnt_2d <= ram_rcnt_1d;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        ram_full <= 'b0;
    end
    else if(ram_rcnt == FIFO_DEPTH - 1 & ram_wen & ~ram_ren) begin
        ram_full <= 'b1;
    end
    else if(~ram_wen & ram_ren) begin
        ram_full <= 'b0;
    end
    else;
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        ram_raddr <= 'b0;
    end
    else if(ram_ren) begin
        ram_raddr <= ram_raddr + 'b1;
    end
    else;
end


assign ram_ren = (fifo_ren | ~r4_vld | ~r3_vld | ~r2_vld | ~r1_vld | ~r0_vld) & ram_rcnt != 'b0;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        ram_ren_1d <= 'b0;
        ram_ren_2d <= 'b0;
    end
    else begin
        ram_ren_1d <= ram_ren;
        ram_ren_2d <= ram_ren_1d;
    end
end

assign stdby_vld = ram_ren_2d;
assign stdby_dat = ram_q;
assign fifo_rdat = r0_vld ? r0 : 'b0; 


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

sdp_ram #(
    .RAM_DATA_WIDTH(RAM_DATA_WIDTH),
    .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)) sdp_ram_inst0 
(
    .clk    (clk),
    .wen    (ram_wen),
    .waddr  (ram_waddr),
    .wdat   (ram_wdat),
    .ren    (ram_ren),
    .raddr  (ram_raddr),
    .q      (ram_q)
);

endmodule
