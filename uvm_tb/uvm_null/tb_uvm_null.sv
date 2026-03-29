module tb_uvm_null;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class null_test extends uvm_test;
    `uvm_component_utils(null_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      #100;
      phase.drop_objection(this);
    endtask
  endclass

  initial begin
    run_test("null_test");
  end
endmodule
