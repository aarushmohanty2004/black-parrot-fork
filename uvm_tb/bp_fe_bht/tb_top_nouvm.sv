`include "bp_common_defines.svh"
`include "bp_fe_defines.svh"

module tb_top_nouvm
 import bp_common_pkg::*;
 import bp_fe_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   );

  logic clk;

  logic init_done_lo;
  logic w_yumi_lo;
  logic [bht_row_width_p-1:0] r_val_lo;
  logic r_pred_lo;
  logic [bht_idx_width_p-1:0] r_idx_lo;
  logic [bht_offset_width_p-1:0] r_offset_lo;

  logic [255:0] r_val_if;
  logic [63:0]  r_idx_if;
  logic [63:0]  r_offset_if;

  assign r_val_if = {{(256-bht_row_width_p){1'b0}}, r_val_lo};
  assign r_idx_if = {{(64-bht_idx_width_p){1'b0}}, r_idx_lo};
  assign r_offset_if = {{(64-bht_offset_width_p){1'b0}}, r_offset_lo};

  bp_fe_bht_if vif
   (.clk(clk)
    ,.init_done(init_done_lo)
    ,.w_yumi(w_yumi_lo)
    ,.r_val(r_val_if)
    ,.r_pred(r_pred_lo)
    ,.r_idx(r_idx_if)
    ,.r_offset(r_offset_if)
    );

  bp_fe_bht
   #(.bp_params_p(bp_params_p))
   dut
    (.clk_i(clk)
     ,.reset_i(vif.reset)
     ,.init_done_o(init_done_lo)
     ,.w_v_i(vif.w_v)
     ,.w_force_i(vif.w_force)
     ,.w_idx_i(vif.w_idx[bht_idx_width_p-1:0])
     ,.w_offset_i(vif.w_offset[bht_offset_width_p-1:0])
     ,.w_ghist_i(vif.w_ghist[ghist_width_p-1:0])
     ,.w_val_i(vif.w_val[bht_row_width_p-1:0])
     ,.w_correct_i(vif.w_correct)
     ,.w_yumi_o(w_yumi_lo)
     ,.r_v_i(vif.r_v)
     ,.r_addr_i(vif.r_addr[vaddr_width_p-1:0])
     ,.r_ghist_i(vif.r_ghist[ghist_width_p-1:0])
     ,.r_val_o(r_val_lo)
     ,.r_pred_o(r_pred_lo)
     ,.r_idx_o(r_idx_lo)
     ,.r_offset_o(r_offset_lo)
     );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    vif.reset = 1'b1;
    vif.clear_inputs();
    repeat (5) @(posedge clk);
    vif.reset = 1'b0;
  end

  initial begin
    repeat (20) @(posedge clk);
    $finish;
  end

endmodule
