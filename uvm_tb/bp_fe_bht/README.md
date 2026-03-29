# bp_fe_bht UVM testbench for Verilator

This directory contains a standalone UVM-oriented unit-level testbench for
`bp_fe/src/v/bp_fe_bht.sv`.

The bench is structured around two interfaces:
- `bp_fe_bht_ctrl_if`: active control interface driven by the UVM driver
- `bp_fe_bht_obs_if`: passive observation interface sampled by the UVM monitor

That split is intentional. A single bidirectional interface triggered a
zero-time convergence issue under Verilator+UVM in this setup, while the split
control/observe pattern runs cleanly for the current supported tests.

## Project files

- `bp_fe_bht_if.sv`: control and observation interfaces
- `bp_fe_bht_uvm_pkg.sv`: sequence item, driver, monitor, scoreboard, env, and supported tests
- `tb_top.sv`: DUT wrapper, clock/reset generation, config export, and `run_test()` entry point
- `flist.f`: local RTL and TB sources for Verilator
- `run_verilator.sh`: root-aware compile and run script with UVM test selection

## Supported tests

The current commit-ready snapshot keeps the tests that are working in the
present Verilator/UVM flow:
- `bp_fe_bht_null_test`
- `bp_fe_bht_min_test`
- `bp_fe_bht_smoke_test`
- `bp_fe_bht_default_read_test`
- `bp_fe_bht_hash_test`
- `bp_fe_bht_rw_collision_noforce_test`

These tests cover:
- reset and BHT initialization completion
- default-row reads after initialization
- gselect-style read index hashing behavior
- same-address read/write behavior for the non-force collision case
- basic UVM bench bring-up through Verilator

## Current limitation

The bench still has a known observability limitation around `r_idx` in the
current Verilator/UVM flow. The scoreboard treats this as a `BHT_OBS` warning
instead of a functional failure, while `r_val`, `r_pred`, `r_offset`, and
write-acceptance checks remain strict.

Write-update stress tests and broader randomized regression were removed from
this commit-ready snapshot because they are not yet stable enough to present as
finished project functionality.

## Notes

- The current run still prints a set of Verilator width warnings from BlackParrot RTL/package code and UVM internals, but the supported tests complete.
- The UVM component-name warnings come from running with `UVM_NO_DPI`; they are noisy but not fatal here.

