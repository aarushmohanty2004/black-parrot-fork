`include "bp_common_defines.svh"
`include "bp_fe_defines.svh"

module tb_idx_debug
 import bp_common_pkg::*;
 import bp_fe_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   );

  logic clk;
  logic reset;
  logic init_done;
  logic w_yumi;
  logic [bht_row_width_p-1:0] r_val;
  logic r_pred;
  logic [bht_idx_width_p-1:0] r_idx;
  logic [bht_offset_width_p-1:0] r_offset;

  logic w_v;
  logic w_force;
  logic [bht_idx_width_p-1:0] w_idx;
  logic [bht_offset_width_p-1:0] w_offset;
  logic [ghist_width_p-1:0] w_ghist;
  logic [bht_row_width_p-1:0] w_val;
  logic w_correct;

  logic r_v;
  logic [vaddr_width_p-1:0] r_addr;
  logic [ghist_width_p-1:0] r_ghist;

  bp_fe_bht
   #(.bp_params_p(bp_params_p))
   dut
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.init_done_o(init_done)
     ,.w_v_i(w_v)
     ,.w_force_i(w_force)
     ,.w_idx_i(w_idx)
     ,.w_offset_i(w_offset)
     ,.w_ghist_i(w_ghist)
     ,.w_val_i(w_val)
     ,.w_correct_i(w_correct)
     ,.w_yumi_o(w_yumi)
     ,.r_v_i(r_v)
     ,.r_addr_i(r_addr)
     ,.r_ghist_i(r_ghist)
     ,.r_val_o(r_val)
     ,.r_pred_o(r_pred)
     ,.r_idx_o(r_idx)
     ,.r_offset_o(r_offset)
     );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset = 1'b1;
    w_v = 1'b0;
    w_force = 1'b0;
    w_idx = '0;
    w_offset = '0;
    w_ghist = '0;
    w_val = '0;
    w_correct = 1'b0;
    r_v = 1'b0;
    r_addr = '0;
    r_ghist = '0;

    repeat (5) @(posedge clk);
    reset = 1'b0;
    wait (init_done);
    repeat (2) @(posedge clk);

    @(negedge clk);
    r_v = 1'b1;
    r_addr = vaddr_width_p'(64'h20a);
    r_ghist = '0;

    @(posedge clk);
    $display("DBG after req: r_addr=0x%0h r_idx=%0d r_offset=%0d", r_addr, r_idx, r_offset);
    @(negedge clk);
    r_v = 1'b0;
    r_addr = '0;

    @(posedge clk);
    $display("DBG one cycle later: r_idx=%0d r_offset=%0d", r_idx, r_offset);
    @(posedge clk);
    $finish;
  end
endmodule
