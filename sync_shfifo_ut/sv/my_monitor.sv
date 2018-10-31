`ifndef MY_MONITOR__SV
`define MY_MONITOR__SV
class my_monitor extends uvm_monitor;

   virtual my_if vif;

   uvm_analysis_port #(my_transaction)  ap;
   
   `uvm_component_utils(my_monitor)
   function new(string name = "my_monitor", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
         `uvm_fatal("my_monitor", "virtual interface must be set for vif!!!")
      ap = new("ap", this);
   endfunction

   extern task main_phase(uvm_phase phase);
   //extern task fifo_monitor(my_transaction tr);
   extern task fifo_monitor();
endclass

task my_monitor::main_phase(uvm_phase phase);
   my_transaction tr;
   while(1) begin
   //   tr = new("tr");
      fifo_monitor();
   //   ap.write(tr);
   end
endtask

task my_monitor::fifo_monitor();
    bit [31:0] fifo_data_q[$];
    bit [31:0] fifo_data;
    parameter FIFO_DEPTH = 'd16;
    parameter FIFO_AE_THRESHOLD = 'd2;
    parameter FIFO_AF_THRESHOLD = 'd6;

    while(1) begin
        @(posedge vif.clk);
        if(vif.rst_n) break;
    end
    while(1) begin
        @(posedge vif.clk);
        // fifo_empty compare thread
        if(fifo_data_q.size == 0) begin
            if(vif.fifo_empty != 1) begin
                `uvm_fatal("FIFO EMPTY ERR", "fifo is empty now, fifo_empty should be set");
            end
        end
        else begin
            if(vif.fifo_empty != 0) begin
                `uvm_fatal("FIFO EMPTY ERR", "fifo is not empty now, fifo_empty should not be set");
            end                
        end
        // fifo_full compare thread
        if(fifo_data_q.size >= FIFO_DEPTH) begin
            if(vif.fifo_full != 1) begin
                `uvm_fatal("FIFO FULL ERR", "fifo is full now, fifo_full should be set");
            end
        end
        else begin
            if(vif.fifo_full != 0) begin
                `uvm_fatal("FIFO FULL ERR", "fifo is not full now, fifo_full should not be set");
            end
        end
        // fifo_rcnt compare thread
        if(vif.fifo_rcnt != fifo_data_q.size) begin
            `uvm_fatal("FIFO RCNT ERR", $sformatf("fifo rcnt expect is %0d, actual is %0d",fifo_data_q.size,vif.fifo_rcnt));
        end
        //  fifo_wcnt compare thread
        if(vif.fifo_wcnt != FIFO_DEPTH - fifo_data_q.size) begin
            `uvm_fatal("FIFO WCNT ERR", $sformatf("fifo wcnt expect is %0d, actual is %0d",FIFO_DEPTH - fifo_data_q.size,vif.fifo_wcnt));
        end
        // fifo_aempty compare thread
        if(fifo_data_q.size <= FIFO_AE_THRESHOLD) begin
            if(vif.fifo_aempty != 1) begin
                `uvm_fatal("FIFO AEMPTY ERR", "fifo is almost empty now, fifo_aempty should be set");
            end
        end
        else begin
            if(vif.fifo_aempty != 0) begin
                `uvm_fatal("FIFO AEMPTY ERR", "fifo is not almost empty now, fifo_aempty should not be set");
            end                
        end
        // fifo_afull compare thread
        if(fifo_data_q.size >= FIFO_AF_THRESHOLD) begin
            if(vif.fifo_afull != 1) begin
                `uvm_fatal("FIFO AFULL ERR", "fifo is almost full now, fifo_afull should be set");
            end
        end
        else begin
            if(vif.fifo_afull != 0) begin
                `uvm_fatal("FIFO AFULL ERR", "fifo is not almost full now, fifo_afull should not be set");
            end                
        end
        // data compare thread
        if(vif.fifo_wen & ~vif.fifo_full) begin
            fifo_data_q.push_back(vif.fifo_wdat);
            `uvm_info("FIFO_PUSH",$sformatf("monitor fifo write data: %0h", vif.fifo_wdat), UVM_HIGH);
        end
        if(vif.fifo_ren & ~vif.fifo_empty) begin
            `uvm_info("FIFO_POP",$sformatf("monitor fifo read data: %0h", vif.fifo_rdat), UVM_LOW);
            if(vif.fifo_rdat != fifo_data_q.pop_front()) begin
                `uvm_fatal("Data Mismatch", "fifo read data mismatch fifo write data");
            end
            else begin
                `uvm_info("Data Compare", "FIFO Data Compare Success", UVM_LOW);
            end
        end
        
    end
endtask

//task my_monitor::fifo_monitor(my_transaction tr);
   //byte unsigned data_q[$];
   //byte unsigned data_array[];
   //logic [7:0] data;
   //logic valid = 0;
   //int data_size;
   //
   //while(1) begin
   //   @(posedge vif.clk);
   //   if(vif.valid) break;
   //end
   //
   //`uvm_info("my_monitor", "begin to collect one pkt", UVM_LOW);
   //while(vif.valid) begin
   //   data_q.push_back(vif.data);
   //   @(posedge vif.clk);
   //end
   //data_size  = data_q.size();   
   //data_array = new[data_size];
   //for ( int i = 0; i < data_size; i++ ) begin
   //   data_array[i] = data_q[i]; 
   //end
   //tr.pload = new[data_size - 18]; //da sa, e_type, crc
   //data_size = tr.unpack_bytes(data_array) / 8; 
   //`uvm_info("my_monitor", "end collect one pkt", UVM_LOW);
//endtask


`endif
