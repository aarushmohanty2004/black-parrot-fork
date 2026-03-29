package bp_fe_bht_uvm_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum int {BP_FE_BHT_OP_READ, BP_FE_BHT_OP_WRITE, BP_FE_BHT_OP_RW} bp_fe_bht_op_e;

  function automatic longint unsigned mask64(input int width);
    longint unsigned one;
    one = 64'd1;
    if (width >= 64) begin
      return '1;
    end
    else if (width <= 0) begin
      return '0;
    end
    else begin
      return (one << width) - 1;
    end
  endfunction

  function automatic bit [255:0] default_row_256(input int row_els);
    bit [255:0] tmp;
    tmp = '0;
    for (int i = 0; i < row_els; i++) begin
      tmp[(2*i)+:2] = 2'b01;
    end
    return tmp;
  endfunction

  function automatic bit [255:0] row_with_counter_256
    (input int row_els, input int offset, input bit [1:0] ctr);
    bit [255:0] tmp;
    tmp = default_row_256(row_els);
    if ((offset >= 0) && (offset < row_els)) begin
      tmp[(2*offset)+:2] = ctr;
    end
    return tmp;
  endfunction

  function automatic bit [63:0] compose_r_addr
    (input int idx_width, input int offset_width, input longint unsigned idx, input longint unsigned offset, input bit hash_bit);
    longint unsigned addr;
    longint unsigned idx_pre_xor;
    addr = '0;
    idx_pre_xor = (idx ^ longint'(hash_bit)) & mask64(idx_width);
    addr |= ((offset & mask64(offset_width)) << (2 + idx_width));
    addr |= (idx_pre_xor << 2);
    addr |= (longint'(hash_bit) << 1);
    return addr[63:0];
  endfunction

  function automatic bit rows_equal(input bit [255:0] a, input bit [255:0] b, input int width_bits);
    for (int i = 0; i < width_bits; i++) begin
      if (a[i] !== b[i]) begin
        return 1'b0;
      end
    end
    return 1'b1;
  endfunction

  class bp_fe_bht_item extends uvm_sequence_item;
    rand bp_fe_bht_op_e op;
    rand int unsigned idle_cycles;

    rand bit w_force;
    rand bit w_correct;
    rand bit [63:0] w_idx;
    rand bit [63:0] w_offset;
    rand bit [63:0] w_ghist;
    rand bit [255:0] w_val;

    rand bit [63:0] r_addr;
    rand bit [63:0] r_ghist;

    bit seen_write;
    bit seen_read;
    bit w_yumi;
    bit [255:0] r_val;
    bit r_pred;
    bit [63:0] r_idx;
    bit [63:0] r_offset;

    `uvm_object_utils(bp_fe_bht_item)

    function new(string name = "bp_fe_bht_item");
      super.new(name);
    endfunction
  endclass

  function automatic bp_fe_bht_item make_read_item
    (input string name, input int unsigned idle_cycles, input bit [63:0] r_addr, input bit [63:0] r_ghist);
    bp_fe_bht_item tr;
    tr = bp_fe_bht_item::type_id::create(name);
    tr.op = BP_FE_BHT_OP_READ;
    tr.idle_cycles = idle_cycles;
    tr.r_addr = r_addr;
    tr.r_ghist = r_ghist;
    return tr;
  endfunction

  function automatic bp_fe_bht_item make_write_item
    (input string name
     , input int unsigned idle_cycles
     , input bit w_force
     , input bit w_correct
     , input bit [63:0] w_idx
     , input bit [63:0] w_offset
     , input bit [63:0] w_ghist
     , input bit [255:0] w_val
     );
    bp_fe_bht_item tr;
    tr = bp_fe_bht_item::type_id::create(name);
    tr.op = BP_FE_BHT_OP_WRITE;
    tr.idle_cycles = idle_cycles;
    tr.w_force = w_force;
    tr.w_correct = w_correct;
    tr.w_idx = w_idx;
    tr.w_offset = w_offset;
    tr.w_ghist = w_ghist;
    tr.w_val = w_val;
    return tr;
  endfunction

  function automatic bp_fe_bht_item make_rw_item
    (input string name
     , input int unsigned idle_cycles
     , input bit w_force
     , input bit w_correct
     , input bit [63:0] w_idx
     , input bit [63:0] w_offset
     , input bit [63:0] w_ghist
     , input bit [255:0] w_val
     , input bit [63:0] r_addr
     , input bit [63:0] r_ghist
     );
    bp_fe_bht_item tr;
    tr = bp_fe_bht_item::type_id::create(name);
    tr.op = BP_FE_BHT_OP_RW;
    tr.idle_cycles = idle_cycles;
    tr.w_force = w_force;
    tr.w_correct = w_correct;
    tr.w_idx = w_idx;
    tr.w_offset = w_offset;
    tr.w_ghist = w_ghist;
    tr.w_val = w_val;
    tr.r_addr = r_addr;
    tr.r_ghist = r_ghist;
    return tr;
  endfunction

  class bp_fe_bht_program_seq extends uvm_sequence #(bp_fe_bht_item);
    `uvm_object_utils(bp_fe_bht_program_seq)

    bp_fe_bht_item items[$];

    function new(string name = "bp_fe_bht_program_seq");
      super.new(name);
    endfunction

    function void add_item(bp_fe_bht_item tr);
      items.push_back(tr);
    endfunction

    virtual task body();
      foreach (items[i]) begin
        start_item(items[i]);
        finish_item(items[i]);
      end
    endtask
  endclass

  class bp_fe_bht_sequencer extends uvm_sequencer #(bp_fe_bht_item);
    `uvm_component_utils(bp_fe_bht_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class bp_fe_bht_driver extends uvm_driver #(bp_fe_bht_item);
    `uvm_component_utils(bp_fe_bht_driver)

    virtual bp_fe_bht_ctrl_if ctrl_vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual bp_fe_bht_ctrl_if)::get(this, "", "ctrl_vif", ctrl_vif)) begin
        `uvm_fatal("NOVIF", "bp_fe_bht_ctrl_if not found in config DB")
      end
    endfunction

    task drive_item(bp_fe_bht_item tr);
      repeat (tr.idle_cycles) @(posedge ctrl_vif.clk);

      @(negedge ctrl_vif.clk);
      ctrl_vif.clear_inputs();

      case (tr.op)
        BP_FE_BHT_OP_READ: begin
          ctrl_vif.r_v     = 1'b1;
          ctrl_vif.r_addr  = tr.r_addr;
          ctrl_vif.r_ghist = tr.r_ghist;
        end
        BP_FE_BHT_OP_WRITE: begin
          ctrl_vif.w_v       = 1'b1;
          ctrl_vif.w_force   = tr.w_force;
          ctrl_vif.w_idx     = tr.w_idx;
          ctrl_vif.w_offset  = tr.w_offset;
          ctrl_vif.w_ghist   = tr.w_ghist;
          ctrl_vif.w_val     = tr.w_val;
          ctrl_vif.w_correct = tr.w_correct;
        end
        BP_FE_BHT_OP_RW: begin
          ctrl_vif.w_v       = 1'b1;
          ctrl_vif.w_force   = tr.w_force;
          ctrl_vif.w_idx     = tr.w_idx;
          ctrl_vif.w_offset  = tr.w_offset;
          ctrl_vif.w_ghist   = tr.w_ghist;
          ctrl_vif.w_val     = tr.w_val;
          ctrl_vif.w_correct = tr.w_correct;
          ctrl_vif.r_v       <= 1'b1;
          ctrl_vif.r_addr    <= tr.r_addr;
          ctrl_vif.r_ghist   <= tr.r_ghist;
        end
      endcase

      @(posedge ctrl_vif.clk);
      @(negedge ctrl_vif.clk);
      ctrl_vif.clear_inputs();
    endtask

    task run_phase(uvm_phase phase);
      bp_fe_bht_item tr;

      ctrl_vif.clear_inputs();
      forever begin
        seq_item_port.get_next_item(tr);
        drive_item(tr);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class bp_fe_bht_monitor extends uvm_component;
    `uvm_component_utils(bp_fe_bht_monitor)

    virtual bp_fe_bht_obs_if obs_vif;
    uvm_analysis_port #(bp_fe_bht_item) ap;
    bp_fe_bht_item pending_tr;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual bp_fe_bht_obs_if)::get(this, "", "obs_vif", obs_vif)) begin
        `uvm_fatal("NOVIF", "bp_fe_bht_obs_if not found in config DB")
      end
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(posedge obs_vif.clk);

        if (pending_tr != null) begin
          pending_tr.r_val    = obs_vif.r_val;
          pending_tr.r_pred   = obs_vif.r_pred;
          pending_tr.r_idx    = obs_vif.r_idx;
          pending_tr.r_offset = obs_vif.r_offset;
          ap.write(pending_tr);
          pending_tr = null;
        end

        #0;
        if (obs_vif.init_done && (obs_vif.r_v || obs_vif.w_v)) begin
          pending_tr = bp_fe_bht_item::type_id::create("pending_tr", this);
          pending_tr.seen_read  = obs_vif.r_v;
          pending_tr.seen_write = obs_vif.w_v;
          pending_tr.w_force    = obs_vif.w_force;
          pending_tr.w_correct  = obs_vif.w_correct;
          pending_tr.w_idx      = obs_vif.w_idx;
          pending_tr.w_offset   = obs_vif.w_offset;
          pending_tr.w_ghist    = obs_vif.w_ghist;
          pending_tr.w_val      = obs_vif.w_val;
          pending_tr.r_addr     = obs_vif.r_addr;
          pending_tr.r_ghist    = obs_vif.r_ghist;
          pending_tr.w_yumi     = obs_vif.w_yumi;
        end
      end
    endtask
  endclass

  class bp_fe_bht_scoreboard extends uvm_component;
    `uvm_component_utils(bp_fe_bht_scoreboard)

    uvm_analysis_imp #(bp_fe_bht_item, bp_fe_bht_scoreboard) analysis_export;

    int bht_idx_width;
    int bht_offset_width;
    int ghist_width;
    int bht_row_width;
    int bht_row_els;

    int txn_count;
    bit [255:0] model_mem [longint unsigned];

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(int)::get(this, "", "bht_idx_width", bht_idx_width)) begin
        `uvm_fatal("NOCFG", "bht_idx_width missing from config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "bht_offset_width", bht_offset_width)) begin
        `uvm_fatal("NOCFG", "bht_offset_width missing from config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "ghist_width", ghist_width)) begin
        `uvm_fatal("NOCFG", "ghist_width missing from config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "bht_row_width", bht_row_width)) begin
        `uvm_fatal("NOCFG", "bht_row_width missing from config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "bht_row_els", bht_row_els)) begin
        `uvm_fatal("NOCFG", "bht_row_els missing from config DB")
      end
    endfunction

    function automatic bit [255:0] get_model_row(longint unsigned addr);
      if (model_mem.exists(addr)) begin
        return model_mem[addr];
      end
      return default_row_256(bht_row_els);
    endfunction

    function void write(bp_fe_bht_item tr);
      longint unsigned idx_mask;
      longint unsigned off_mask;
      longint unsigned ghist_mask;
      longint unsigned w_addr;
      longint unsigned r_hash;
      longint unsigned r_idx_exp;
      longint unsigned r_offset_exp;
      longint unsigned r_addr_model;
      bit rw_same_addr;
      bit suppress_read;
      bit suppress_write;
      bit [255:0] expected_row;
      bit [255:0] updated_row;
      int pred_bit;

      txn_count++;
      idx_mask   = mask64(bht_idx_width);
      off_mask   = mask64(bht_offset_width);
      ghist_mask = mask64(ghist_width);

      w_addr = ((tr.w_ghist & ghist_mask) << bht_idx_width) | (tr.w_idx & idx_mask);
      r_hash = (tr.r_addr >> 1) & 64'd1;
      r_idx_exp = ((tr.r_addr >> 2) & idx_mask) ^ r_hash;
      r_offset_exp = (tr.r_addr >> (2 + bht_idx_width)) & off_mask;
      r_addr_model = ((tr.r_ghist & ghist_mask) << bht_idx_width) | (r_idx_exp & idx_mask);

      rw_same_addr = tr.seen_read && tr.seen_write && (r_addr_model == w_addr);
      suppress_read = rw_same_addr && tr.w_force;
      suppress_write = rw_same_addr && !tr.w_force;

      if (tr.seen_read) begin
        if (tr.r_idx !== r_idx_exp) begin
          `uvm_error("BHT_SCB", $sformatf("r_idx mismatch exp=%0d got=%0d", r_idx_exp, tr.r_idx))
        end
        if (tr.r_offset !== r_offset_exp) begin
          `uvm_error("BHT_SCB", $sformatf("r_offset mismatch exp=%0d got=%0d", r_offset_exp, tr.r_offset))
        end
      end

      if (tr.seen_write) begin
        if (tr.w_yumi !== !suppress_write) begin
          `uvm_error("BHT_SCB", $sformatf("w_yumi mismatch exp=%0d got=%0d", !suppress_write, tr.w_yumi))
        end
      end

      if (tr.seen_read && !suppress_read) begin
        expected_row = get_model_row(r_addr_model);
        if (!rows_equal(tr.r_val, expected_row, bht_row_width)) begin
          `uvm_error("BHT_SCB", $sformatf("r_val mismatch exp=0x%0h got=0x%0h", expected_row, tr.r_val))
        end

        pred_bit = (bht_row_els > 1) ? ((int'(r_offset_exp) << 1) + 1) : 1;
        if (tr.r_pred !== expected_row[pred_bit]) begin
          `uvm_error("BHT_SCB", $sformatf("r_pred mismatch exp=%0d got=%0d", expected_row[pred_bit], tr.r_pred))
        end
      end

      if (tr.seen_write && !suppress_write) begin
        updated_row = get_model_row(w_addr);
        for (int i = 0; i < bht_row_els; i++) begin
          if (i == int'(tr.w_offset)) begin
            updated_row[2*i]   = ~tr.w_correct;
            updated_row[2*i+1] = tr.w_val[2*i+1] ^ (~tr.w_correct & tr.w_val[2*i]);
          end
          else begin
            updated_row[2*i]   = tr.w_val[2*i];
            updated_row[2*i+1] = tr.w_val[2*i+1];
          end
        end
        model_mem[w_addr] = updated_row;
      end
    endfunction
  endclass

  class bp_fe_bht_agent extends uvm_component;
    `uvm_component_utils(bp_fe_bht_agent)

    bp_fe_bht_sequencer sequencer;
    bp_fe_bht_driver driver;
    bp_fe_bht_monitor monitor;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sequencer = bp_fe_bht_sequencer::type_id::create("sequencer", this);
      driver    = bp_fe_bht_driver::type_id::create("driver", this);
      monitor   = bp_fe_bht_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

  class bp_fe_bht_env extends uvm_env;
    `uvm_component_utils(bp_fe_bht_env)

    bp_fe_bht_agent agent;
    bp_fe_bht_scoreboard scoreboard;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = bp_fe_bht_agent::type_id::create("agent", this);
      scoreboard = bp_fe_bht_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.monitor.ap.connect(scoreboard.analysis_export);
    endfunction
  endclass

  class bp_fe_bht_base_test extends uvm_test;
    `uvm_component_utils(bp_fe_bht_base_test)

    bp_fe_bht_env env;
    virtual bp_fe_bht_obs_if obs_vif;

    int bht_idx_width;
    int bht_offset_width;
    int ghist_width;
    int bht_row_width;
    int bht_row_els;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = bp_fe_bht_env::type_id::create("env", this);
      if (!uvm_config_db#(virtual bp_fe_bht_obs_if)::get(this, "", "obs_vif", obs_vif)) begin
        `uvm_fatal("NOVIF", "bp_fe_bht_obs_if not found in config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "bht_idx_width", bht_idx_width)) begin
        `uvm_fatal("NOCFG", "bht_idx_width missing from config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "bht_offset_width", bht_offset_width)) begin
        `uvm_fatal("NOCFG", "bht_offset_width missing from config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "ghist_width", ghist_width)) begin
        `uvm_fatal("NOCFG", "ghist_width missing from config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "bht_row_width", bht_row_width)) begin
        `uvm_fatal("NOCFG", "bht_row_width missing from config DB")
      end
      if (!uvm_config_db#(int)::get(this, "", "bht_row_els", bht_row_els)) begin
        `uvm_fatal("NOCFG", "bht_row_els missing from config DB")
      end
    endfunction

    task automatic wait_for_init_done();
      wait (obs_vif.init_done === 1'b1);
      repeat (2) @(posedge obs_vif.clk);
    endtask

    task automatic run_program_seq
      (uvm_phase phase, bp_fe_bht_program_seq seq, input int unsigned drain_cycles = 5);
      phase.raise_objection(this);
      wait_for_init_done();
      seq.start(env.agent.sequencer);
      repeat (drain_cycles) @(posedge obs_vif.clk);
      phase.drop_objection(this);
    endtask

    function automatic bit [255:0] default_row();
      return default_row_256(bht_row_els);
    endfunction

    function automatic bit [255:0] row_with_counter(input int offset, input bit [1:0] ctr);
      return row_with_counter_256(bht_row_els, offset, ctr);
    endfunction

    function automatic bit [63:0] make_r_addr
      (input longint unsigned idx, input longint unsigned offset, input bit hash_bit = 1'b0);
      return compose_r_addr(bht_idx_width, bht_offset_width, idx, offset, hash_bit);
    endfunction

    function automatic bit [63:0] rand64();
      return {$urandom(), $urandom()};
    endfunction

    function automatic bit [255:0] rand256();
      return {rand64(), rand64(), rand64(), rand64()};
    endfunction
  endclass

  class bp_fe_bht_smoke_test extends bp_fe_bht_base_test;
    `uvm_component_utils(bp_fe_bht_smoke_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      bp_fe_bht_program_seq seq;

      seq = bp_fe_bht_program_seq::type_id::create("seq");
      seq.add_item(make_read_item("read_default", 1, make_r_addr(0, 0, 0), '0));
      seq.add_item(make_write_item("write_one_counter", 1, 1'b0, 1'b0, 0, 0, 0, default_row()));
      seq.add_item(make_read_item("read_back", 2, make_r_addr(0, 0, 0), '0));
      run_program_seq(phase, seq);
    endtask
  endclass

  class bp_fe_bht_default_read_test extends bp_fe_bht_base_test;
    `uvm_component_utils(bp_fe_bht_default_read_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      bp_fe_bht_program_seq seq;

      seq = bp_fe_bht_program_seq::type_id::create("seq");
      seq.add_item(make_read_item("read_default_row0", 1, make_r_addr(0, 0, 0), '0));
      seq.add_item(make_read_item("read_default_row1", 1, make_r_addr(3, 1, 1), 0));
      seq.add_item(make_read_item("read_default_row2", 1, make_r_addr(5, 2, 0), 1));
      run_program_seq(phase, seq);
    endtask
  endclass

  class bp_fe_bht_hash_test extends bp_fe_bht_base_test;
    `uvm_component_utils(bp_fe_bht_hash_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      bp_fe_bht_program_seq seq;

      seq = bp_fe_bht_program_seq::type_id::create("seq");
      seq.add_item(make_read_item("hash_zero", 1, make_r_addr(6, 1, 0), 0));
      seq.add_item(make_read_item("hash_one", 1, make_r_addr(6, 1, 1), 0));
      seq.add_item(make_read_item("hash_other_idx", 1, make_r_addr(11, 3, 1), 1));
      run_program_seq(phase, seq);
    endtask
  endclass

  class bp_fe_bht_single_write_test extends bp_fe_bht_base_test;
    `uvm_component_utils(bp_fe_bht_single_write_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      bp_fe_bht_program_seq seq;
      bit [255:0] write_row;

      write_row = row_with_counter(2, 2'b10);
      seq = bp_fe_bht_program_seq::type_id::create("seq");
      seq.add_item(make_write_item("single_write", 1, 1'b0, 1'b1, 2, 2, 1, write_row));
      seq.add_item(make_read_item("read_written_entry", 2, make_r_addr(2, 2, 0), 1));
      seq.add_item(make_read_item("read_untouched_entry", 1, make_r_addr(7, 0, 1), 0));
      run_program_seq(phase, seq);
    endtask
  endclass

  class bp_fe_bht_rw_collision_force_test extends bp_fe_bht_base_test;
    `uvm_component_utils(bp_fe_bht_rw_collision_force_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      bp_fe_bht_program_seq seq;
      bit [255:0] write_row;
      bit [63:0] coll_addr;

      write_row = row_with_counter(1, 2'b11);
      coll_addr = make_r_addr(4, 1, 0);

      seq = bp_fe_bht_program_seq::type_id::create("seq");
      seq.add_item(make_rw_item("rw_collision_force", 1, 1'b1, 1'b1, 4, 1, 2, write_row, coll_addr, 2));
      seq.add_item(make_read_item("read_after_force_collision", 2, coll_addr, 2));
      run_program_seq(phase, seq);
    endtask
  endclass

  class bp_fe_bht_rw_collision_noforce_test extends bp_fe_bht_base_test;
    `uvm_component_utils(bp_fe_bht_rw_collision_noforce_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      bp_fe_bht_program_seq seq;
      bit [255:0] write_row;
      bit [63:0] coll_addr;

      write_row = row_with_counter(3, 2'b00);
      coll_addr = make_r_addr(1, 3, 1);

      seq = bp_fe_bht_program_seq::type_id::create("seq");
      seq.add_item(make_rw_item("rw_collision_noforce", 1, 1'b0, 1'b0, 1, 3, 3, write_row, coll_addr, 3));
      seq.add_item(make_read_item("read_after_noforce_collision", 2, coll_addr, 3));
      run_program_seq(phase, seq);
    endtask
  endclass

  class bp_fe_bht_random_mix_test extends bp_fe_bht_base_test;
    `uvm_component_utils(bp_fe_bht_random_mix_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      bp_fe_bht_program_seq seq;
      bp_fe_bht_item tr;
      int unsigned choose;
      int unsigned item_count;
      bit [63:0] idx_masked;
      bit [63:0] offset_masked;
      bit [63:0] ghist_masked;
      bit [63:0] coll_addr;
      bit hash_bit;

      seq = bp_fe_bht_program_seq::type_id::create("seq");
      item_count = 25;

      for (int i = 0; i < item_count; i++) begin
        choose = $urandom_range(0, 2);
        idx_masked = rand64() & mask64(bht_idx_width);
        offset_masked = rand64() & mask64(bht_offset_width);
        ghist_masked = rand64() & mask64(ghist_width);
        hash_bit = $urandom_range(0, 1);

        case (choose)
          0: begin
            tr = make_read_item
              ($sformatf("rand_read_%0d", i)
               , $urandom_range(0, 2)
               , make_r_addr(idx_masked, offset_masked, hash_bit)
               , ghist_masked
               );
          end
          1: begin
            tr = make_write_item
              ($sformatf("rand_write_%0d", i)
               , $urandom_range(0, 2)
               , $urandom_range(0, 1)
               , $urandom_range(0, 1)
               , idx_masked
               , offset_masked
               , ghist_masked
               , rand256()
               );
          end
          default: begin
            if ($urandom_range(0, 3) == 0) begin
              coll_addr = make_r_addr(idx_masked, offset_masked, hash_bit);
              tr = make_rw_item
                ($sformatf("rand_rw_collision_%0d", i)
                 , $urandom_range(0, 2)
                 , $urandom_range(0, 1)
                 , $urandom_range(0, 1)
                 , idx_masked
                 , offset_masked
                 , ghist_masked
                 , rand256()
                 , coll_addr
                 , ghist_masked
                 );
            end
            else begin
              tr = make_rw_item
                ($sformatf("rand_rw_%0d", i)
                 , $urandom_range(0, 2)
                 , $urandom_range(0, 1)
                 , $urandom_range(0, 1)
                 , idx_masked
                 , offset_masked
                 , ghist_masked
                 , rand256()
                 , make_r_addr(rand64() & mask64(bht_idx_width), rand64() & mask64(bht_offset_width), $urandom_range(0, 1))
                 , rand64() & mask64(ghist_width)
                 );
            end
          end
        endcase
        seq.add_item(tr);
      end

      run_program_seq(phase, seq, 8);
    endtask
  endclass

  class bp_fe_bht_min_test extends bp_fe_bht_base_test;
    `uvm_component_utils(bp_fe_bht_min_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      wait_for_init_done();
      repeat (20) @(posedge obs_vif.clk);
      phase.drop_objection(this);
    endtask
  endclass

  class bp_fe_bht_null_test extends uvm_test;
    `uvm_component_utils(bp_fe_bht_null_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      #100;
      phase.drop_objection(this);
    endtask
  endclass

endpackage




