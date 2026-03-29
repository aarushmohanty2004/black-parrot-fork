#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

test_name="${1:-bp_fe_bht_smoke_test}"
shift $(( $# > 0 ? 1 : 0 )) || true

find_uvm_home() {
  if [[ -n "${UVM_HOME:-}" && -f "${UVM_HOME}/uvm_pkg.sv" ]]; then
    printf '%s\n' "$UVM_HOME"
    return 0
  fi

  local candidates=(
    "/home/aarushmohanty2004/uvm-verilator/src"
    "/home/aarushmohanty2004/1800.2-2017-1.0/src"
  )

  local cand
  for cand in "${candidates[@]}"; do
    if [[ -f "$cand/uvm_pkg.sv" ]]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done

  return 1
}

find_verilator_bin() {
  local candidates=(
    "/home/aarushmohanty2004/verilator/bin/verilator"
    "$(command -v verilator 2>/dev/null || true)"
  )

  local cand
  for cand in "${candidates[@]}"; do
    if [[ -n "$cand" && -x "$cand" ]]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done

  return 1
}

uvm_home="$(find_uvm_home || true)"
if [[ -z "$uvm_home" ]]; then
  echo "Unable to locate UVM sources."
  echo "Set UVM_HOME to a directory that contains uvm_pkg.sv."
  exit 1
fi

verilator_bin="$(find_verilator_bin || true)"
if [[ -z "$verilator_bin" ]]; then
  echo "Unable to locate a Verilator binary."
  exit 1
fi

cd "$repo_root"

echo "Using UVM_HOME=$uvm_home"
echo "Using VERILATOR=$verilator_bin"
echo "Running UVM test: $test_name"
"$verilator_bin" --version
"$verilator_bin" -sv --binary --timing -j "$(nproc)" \
  -Wno-fatal --assert --trace-fst \
  --top-module tb_top \
  +incdir+"$uvm_home" \
  +define+UVM_NO_DPI \
  "$uvm_home/uvm_pkg.sv" \
  -f uvm_tb/bp_fe_bht/flist.f

./obj_dir/Vtb_top +UVM_TESTNAME="$test_name" "$@"
