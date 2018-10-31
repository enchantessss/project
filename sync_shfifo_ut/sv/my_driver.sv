`ifndef MY_DRIVER__SV
`define MY_DRIVER__SV
class my_driver extends uvm_driver#(my_transaction);

   virtual my_if vif;

   `uvm_component_utils(my_driver)
   function new(string name = "my_driver", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
         `uvm_fatal("my_driver", "virtual interface must be set for vif!!!")
   endfunction

   extern task main_phase(uvm_phase phase);
   extern task drive_fifo_wr(my_transaction tr);
   extern task drive_fifo_rd(my_transaction tr);
endclass

task my_driver::main_phase(uvm_phase phase);
    vif.fifo_wen <= 'b0;
    vif.fifo_wdat <= 'b0;
    vif.fifo_ren <= 'b0;
    while(!vif.rst_n)
        @(posedge vif.clk);
    while(1) begin
        seq_item_port.get_next_item(req);
        fork
            drive_fifo_wr(req);
            drive_fifo_rd(req);
        join_any // Make go, when any of them finish, in this way, write and read will not block each other.
        seq_item_port.item_done();
    end
endtask

task my_driver::drive_fifo_wr(my_transaction tr);
    int wr_length;
    if(tr.wr & tr.wr_len != 0) begin
        `uvm_info("my_driver", "begin to drive fifo write", UVM_HIGH);
        wr_length = tr.wr_len;
        `uvm_info("FIFO_WRITE", $sformatf("fifo write length: %0d", wr_length), UVM_LOW);
    end
    while(wr_length != 0) begin
        @(posedge vif.clk);
        if(vif.fifo_full != 1) begin
            vif.fifo_wen <= 'b1;
            vif.fifo_wdat <= tr.wr_data + wr_length;
            wr_length --;
        end
        else begin
            wr_length = 0;
            vif.fifo_wen <= 'b0;
            vif.fifo_wdat <= 'b0;
        end
    end
    @(posedge vif.clk);
    vif.fifo_wen <= 'b0;
    vif.fifo_wdat <= 'b0;
endtask

task my_driver::drive_fifo_rd(my_transaction tr);
    int rd_length;
    if(tr.rd & tr.rd_len != 0) begin
        `uvm_info("my_driver", "begin to drive fifo read", UVM_HIGH);
        rd_length = tr.rd_len;
        `uvm_info("FIFO_READ", $sformatf("fifo read length: %0d", rd_length), UVM_LOW);
    end
    while(rd_length != 0) begin
        @(posedge vif.clk);
        if(vif.fifo_empty != 1) begin
            vif.fifo_ren <= 'b1;
            rd_length --;
        end
        else begin
            vif.fifo_ren <= 'b0;
        end
    end
    @(posedge vif.clk);
    vif.fifo_ren <= 'b0;
endtask

`endif
