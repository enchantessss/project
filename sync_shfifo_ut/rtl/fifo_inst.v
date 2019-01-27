module fifo_inst(
    input clk,
    input rst_n
);


sync_shfifo sync_shfifo_inst(
    .clk    (clk),
    .rst_n  (rst_n)
);

endmodule
