`ifndef MY_CASE0__SV
`define MY_CASE0__SV
class case0_sequence extends uvm_sequence #(my_transaction);
   my_transaction m_trans;
   int i;

   function  new(string name= "case0_sequence");
      super.new(name);
   endfunction 
   
   virtual task body();
      if(starting_phase != null) 
         starting_phase.raise_objection(this);
      repeat (100) begin
          i = i + 16;;
          `uvm_do_with(m_trans, {m_trans.wr_data == i;});

         //`uvm_do_with(m_trans, {m_trans.wr == 1;
         //                       m_trans.wr_len == 18;
         //                       m_trans.rd == 1;
         //                       m_trans.rd_len == 2;})

         //`uvm_do_with(m_trans, {m_trans.wr == 1;
         //                       m_trans.wr_len == 6;
         //                       m_trans.rd == 0;
         //                       m_trans.rd_len == 0;})

         //`uvm_do_with(m_trans, {m_trans.wr == 0;
         //                       m_trans.wr_len == 6;
         //                       m_trans.rd == 1;
         //                       m_trans.rd_len == 8;})                               
      end
      #10us;
      if(starting_phase != null) 
         starting_phase.drop_objection(this);
   endtask

   `uvm_object_utils(case0_sequence)
endclass


class my_case0 extends base_test;

   function new(string name = "my_case0", uvm_component parent = null);
      super.new(name,parent);
   endfunction 
   extern virtual function void build_phase(uvm_phase phase); 
   extern virtual function void end_of_elaboration_phase(uvm_phase phase); 
   `uvm_component_utils(my_case0)
endclass


function void my_case0::build_phase(uvm_phase phase);
   super.build_phase(phase);

   uvm_config_db#(uvm_object_wrapper)::set(this, 
                                           "env.i_agt.sqr.main_phase", 
                                           "default_sequence", 
                                           case0_sequence::type_id::get());
endfunction

function void my_case0::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    //uvm_top.print_topology();
endfunction
`endif
