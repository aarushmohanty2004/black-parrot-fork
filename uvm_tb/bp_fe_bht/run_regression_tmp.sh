#!/usr/bin/env bash
set -euo pipefail
cd /home/aarushmohanty2004/gsoc-workspace/black-parrot-fork
/home/aarushmohanty2004/verilator/bin/verilator -sv --binary --timing -j 4 -Wno-fatal --assert --trace-fst --top-module tb_top +incdir+/home/aarushmohanty2004/1800.2-2017-1.0/src +define+UVM_NO_DPI /home/aarushmohanty2004/1800.2-2017-1.0/src/uvm_pkg.sv -f uvm_tb/bp_fe_bht/flist.f >/tmp/bht_build.log 2>&1
for t in bp_fe_bht_smoke_test bp_fe_bht_default_read_test bp_fe_bht_hash_test bp_fe_bht_single_write_test bp_fe_bht_rw_collision_force_test bp_fe_bht_rw_collision_noforce_test bp_fe_bht_random_mix_test; do
  echo ===
