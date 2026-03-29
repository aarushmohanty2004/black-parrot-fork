interface bp_fe_bht_ctrl_if
 (input logic clk);

  logic reset = 1'b0;

  logic w_v = 1'b0;
  logic w_force = 1'b0;
  logic [63:0] w_idx = '0;
  logic [63:0] w_offset = '0;
  logic [63:0] w_ghist = '0;
  logic [255:0] w_val = '0;
  logic w_correct = 1'b0;

  logic r_v = 1'b0;
  logic [63:0] r_addr = '0;
  logic [63:0] r_ghist = '0;

  task automatic clear_inputs();
    w_v       = 1'b0;
    w_force   = 1'b0;
    w_idx     = '0;
    w_offset  = '0;
    w_ghist   = '0;
    w_val     = '0;
    w_correct = 1'b0;
    r_v       = 1'b0;
    r_addr    = '0;
    r_ghist   = '0;
  endtask

endinterface

interface bp_fe_bht_obs_if
 (input logic clk
  , input logic reset
  , input logic init_done
  , input logic w_v
  , input logic w_force
  , input logic [63:0] w_idx
  , input logic [63:0] w_offset
  , input logic [63:0] w_ghist
  , input logic [255:0] w_val
  , input logic w_correct
  , input logic w_yumi
  , input logic r_v
  , input logic [63:0] r_addr
  , input logic [63:0] r_ghist
  , input logic [255:0] r_val
  , input logic r_pred
  , input logic [63:0] r_idx
  , input logic [63:0] r_offset
  );
endinterface
