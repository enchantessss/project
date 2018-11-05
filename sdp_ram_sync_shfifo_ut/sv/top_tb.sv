`timescale 1ns/1ps
`include "uvm_macros.svh"

`include "my_if.sv"
`include "my_transaction.sv"
`include "my_sequencer.sv"
`include "my_driver.sv"
`include "my_monitor.sv"
`include "my_agent.sv"
`include "my_model.sv"
`include "my_scoreboard.sv"
`include "my_env.sv"
`include "base_test.sv"
`include "my_case0.sv"
//`include "my_case1.sv"

module top_tb;

reg clk;
reg rst_n;
//reg[7:0] rxd;
//reg rx_dv;
//wire[7:0] txd;
//wire tx_en;

my_if fifo_if(clk, rst_n);
sdp_ram_sync_shfifo #(
    .FIFO_WIDTH(32),
    .FIFO_ADDR(4),
    .FIFO_AE_THRESHOLD(2),
    .FIFO_AF_THRESHOLD(6)     
    ) my_dut(
    .clk                (clk                                   ),
    .rst_n              (rst_n                                 ),
    .fifo_wen           (fifo_if.fifo_wen & ~fifo_if.fifo_full ),
    .fifo_wdat          (fifo_if.fifo_wdat                     ),
    .fifo_ren           (fifo_if.fifo_ren & ~fifo_if.fifo_empty),
    .fifo_rdat          (fifo_if.fifo_rdat                     ),
    .fifo_empty         (fifo_if.fifo_empty                    ),
    .fifo_full          (fifo_if.fifo_full                     ),
    .fifo_aempty        (fifo_if.fifo_aempty                   ),
    .fifo_afull         (fifo_if.fifo_afull                    ),
    .fifo_wcnt          (fifo_if.fifo_wcnt                     ),
    .fifo_rcnt          (fifo_if.fifo_rcnt                     ),
    .fifo_wr_full_err   (fifo_if.fifo_wr_full_err              ),
    .fifo_rd_empty_err  (fifo_if.fifo_rd_empty_err             )
    );

initial begin
   clk = 0;
   forever begin
      #100 clk = ~clk;
   end
end

initial begin
   rst_n = 1'b0;
   #1000;
   rst_n = 1'b1;
end

initial begin
   run_test();
end

initial begin
   $vcdpluson();
end

initial begin
   uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.i_agt.drv", "vif", fifo_if);
   uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.i_agt.mon", "vif", fifo_if);
   uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.o_agt.mon", "vif", fifo_if);
end

endmodule
