`include "bp_common_defines.svh"
`include "bp_fe_defines.svh"

module tb_top
 import uvm_pkg::*;
 import bp_common_pkg::*;
 import bp_fe_pkg::*;
 import bp_fe_bht_uvm_pkg::*;
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

  logic [63:0]  w_idx_obs;
  logic [63:0]  w_offset_obs;
  logic [63:0]  w_ghist_obs;
  logic [255:0] w_val_obs;
  logic [63:0]  r_addr_obs;
  logic [63:0]  r_ghist_obs;
  logic [255:0] r_val_obs;
  logic [63:0]  r_idx_obs;
  logic [63:0]  r_offset_obs;

  assign w_idx_obs    = {{(64-bht_idx_width_p){1'b0}}, ctrl_if.w_idx[bht_idx_width_p-1:0]};
  assign w_offset_obs = {{(64-bht_offset_width_p){1'b0}}, ctrl_if.w_offset[bht_offset_width_p-1:0]};
  assign w_ghist_obs  = {{(64-ghist_width_p){1'b0}}, ctrl_if.w_ghist[ghist_width_p-1:0]};
  assign w_val_obs    = {{(256-bht_row_width_p){1'b0}}, ctrl_if.w_val[bht_row_width_p-1:0]};
  assign r_addr_obs   = {{(64-vaddr_width_p){1'b0}}, ctrl_if.r_addr[vaddr_width_p-1:0]};
  assign r_ghist_obs  = {{(64-ghist_width_p){1'b0}}, ctrl_if.r_ghist[ghist_width_p-1:0]};
  assign r_val_obs    = {{(256-bht_row_width_p){1'b0}}, r_val_lo};
  assign r_idx_obs    = {{(64-bht_idx_width_p){1'b0}}, r_idx_lo};
  assign r_offset_obs = {{(64-bht_offset_width_p){1'b0}}, r_offset_lo};

  bp_fe_bht_ctrl_if ctrl_if
   (.clk(clk));

  bp_fe_bht_obs_if obs_if
   (.clk(clk)
    ,.reset(ctrl_if.reset)
    ,.init_done(init_done_lo)
    ,.w_v(ctrl_if.w_v)
    ,.w_force(ctrl_if.w_force)
    ,.w_idx(w_idx_obs)
    ,.w_offset(w_offset_obs)
    ,.w_ghist(w_ghist_obs)
    ,.w_val(w_val_obs)
    ,.w_correct(ctrl_if.w_correct)
    ,.w_yumi(w_yumi_lo)
    ,.r_v(ctrl_if.r_v)
    ,.r_addr(r_addr_obs)
    ,.r_ghist(r_ghist_obs)
    ,.r_val(r_val_obs)
    ,.r_pred(r_pred_lo)
    ,.r_idx(r_idx_obs)
    ,.r_offset(r_offset_obs)
    );

  bp_fe_bht
   #(.bp_params_p(bp_params_p))
   dut
    (.clk_i(clk)
     ,.reset_i(ctrl_if.reset)
     ,.init_done_o(init_done_lo)
     ,.w_v_i(ctrl_if.w_v)
     ,.w_force_i(ctrl_if.w_force)
     ,.w_idx_i(ctrl_if.w_idx[bht_idx_width_p-1:0])
     ,.w_offset_i(ctrl_if.w_offset[bht_offset_width_p-1:0])
     ,.w_ghist_i(ctrl_if.w_ghist[ghist_width_p-1:0])
     ,.w_val_i(ctrl_if.w_val[bht_row_width_p-1:0])
     ,.w_correct_i(ctrl_if.w_correct)
     ,.w_yumi_o(w_yumi_lo)
     ,.r_v_i(ctrl_if.r_v)
     ,.r_addr_i(ctrl_if.r_addr[vaddr_width_p-1:0])
     ,.r_ghist_i(ctrl_if.r_ghist[ghist_width_p-1:0])
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
    ctrl_if.reset = 1'b1;
    ctrl_if.clear_inputs();
    repeat (5) @(posedge clk);
    ctrl_if.reset = 1'b0;
  end

  initial begin
    uvm_config_db#(virtual bp_fe_bht_ctrl_if)::set(null, "*", "ctrl_vif", ctrl_if);
    uvm_config_db#(virtual bp_fe_bht_obs_if)::set(null, "*", "obs_vif", obs_if);
    uvm_config_db#(int)::set(null, "*", "bht_idx_width", bht_idx_width_p);
    uvm_config_db#(int)::set(null, "*", "bht_offset_width", bht_offset_width_p);
    uvm_config_db#(int)::set(null, "*", "ghist_width", ghist_width_p);
    uvm_config_db#(int)::set(null, "*", "bht_row_width", bht_row_width_p);
    uvm_config_db#(int)::set(null, "*", "bht_row_els", bht_row_els_p);
    run_test();
  end

endmodule
