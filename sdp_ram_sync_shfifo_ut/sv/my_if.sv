`ifndef MY_IF__SV
`define MY_IF__SV

parameter FIFO_WIDTH = 32;
parameter FIFO_ADDR  = 4;
parameter FIFO_DEPTH = 1 << FIFO_ADDR;
parameter FIFO_AE_THRESHOLD = 1;
parameter FIFO_AF_THRESHOLD = FIFO_DEPTH -1; 

interface my_if(input clk, input rst_n);

    logic                      fifo_wen         ;
    logic [FIFO_WIDTH-1 :0]    fifo_wdat        ;
    logic                      fifo_ren         ;
    logic [FIFO_WIDTH-1 :0]    fifo_rdat        ;
    logic                      fifo_empty       ;
    logic                      fifo_full        ;
    logic                      fifo_aempty      ;
    logic                      fifo_afull       ;
    logic [FIFO_ADDR :0]       fifo_wcnt        ;
    logic [FIFO_ADDR :0]       fifo_rcnt        ;
    logic                      fifo_wr_full_err ;
    logic                      fifo_rd_empty_err;

endinterface

`endif
