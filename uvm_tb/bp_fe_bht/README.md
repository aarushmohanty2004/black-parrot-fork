# bp_fe_bht UVM testbench for Verilator

This directory contains a standalone UVM-oriented unit-level testbench for
`bp_fe/src/v/bp_fe_bht.sv`.

The bench is structured around two interfaces:
- `bp_fe_bht_ctrl_if`: active control interface driven by the UVM driver
- `bp_fe_bht_obs_if`: passive observation interface sampled by the UVM monitor

That split is intentional. A single bidirectional interface triggered a
zero-time convergence issue under Verilator+UVM in this setup, while the split
control/observe pattern runs cleanly and is a better long-term UVM shape anyway.

## Current contents

- `bp_fe_bht_if.sv`: control and observation interfaces
- `bp_fe_bht_uvm_pkg.sv`: sequence item, smoke sequence, driver, monitor, scoreboard, env, tests
- `tb_top.sv`: DUT wrapper, clock/reset generation, config export, `run_test()` entry point
- `flist.f`: local RTL and TB sources for Verilator
- `run_verilator.sh`: root-aware compile and run script with UVM test selection

## Verified tests

These were run successfully with local Verilator and the Accellera UVM 2017 tree:
- `bp_fe_bht_null_test`
- `bp_fe_bht_smoke_test`

The smoke test checks:
- reset/init completes and `init_done_o` asserts
- a default row can be read after initialization
- a write to one 2-bit entry is accepted
- a following read observes the expected row contents and prediction bit
- the gselect-derived `r_idx_o` and `r_offset_o` match the RTL equations


## Notes

- The current run still prints a set of Verilator width warnings from BlackParrot RTL/package code and UVM internals, but the verified UVM tests complete successfully.
- The UVM component-name warnings come from running with `UVM_NO_DPI`; they are noisy but not fatal here.
- Extra debug artifacts used during bring-up, such as `tb_top_nouvm.sv`, were kept because they are useful when isolating simulator/runtime issues.
