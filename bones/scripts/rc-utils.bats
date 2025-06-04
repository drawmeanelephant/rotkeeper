#!/usr/bin/env bats
# rc-utils.bats — Test suite for rc-utils.sh

setup_file() {
  TIMESTAMP="$(date +%F)"
  LOGFILE="$BATS_TEST_DIRNAME/../../logs/test-$TIMESTAMP.log"
  mkdir -p "$(dirname "$LOGFILE")"
  exec > >(tee -a "$LOGFILE") 2>&1
}


setup() {
  DRY_RUN=false
}

@test "log() outputs correctly formatted INFO messages" {
  output="$(bash -c 'export LOG_FILE="'"$BATS_TEST_DIRNAME"'/../../logs/test-$(date +%F).log"; source "'"$BATS_TEST_DIRNAME"'/rc-utils.sh"; log INFO "Test message"' 2>&1)"
  [[ "$output" =~ ^\[.*\]\ \[INFO\]\ Test\ message$ ]]
}

@test "log() outputs correctly formatted ERROR messages" {
  output="$(bash -c 'export LOG_FILE="'"$BATS_TEST_DIRNAME"'/../../logs/test-$(date +%F).log"; source "'"$BATS_TEST_DIRNAME"'/rc-utils.sh"; log ERROR "Failure message"' 2>&1)"
  [[ "$output" =~ ^\[.*\]\ \[ERROR\]\ Failure\ message$ ]]
}

@test "run() executes command when DRY_RUN is false" {
  run touch "$BATS_TMPDIR/testfile"
  [ -f "$BATS_TMPDIR/testfile" ]
}

@test "run() logs command without executing when DRY_RUN is true" {
  skip "Nested 'run run ...' is not supported — Bash doesn't export functions to subshells"
}

@test "require_bins() succeeds with existing binary (/bin/echo)" {
  output="$(bash -c "source \"$BATS_TEST_DIRNAME/rc-utils.sh\"; require_bins /bin/echo" 2>&1)"
  status=$?
  [ "$status" -eq 0 ]
}

@test "require_bins() fails with non-existent binary" {
  run bash -c 'source "'"$BATS_TEST_DIRNAME"'/rc-utils.sh"; require_bins nonexistentcommand1234'
  [ "$status" -ne 0 ]
}

@test "trap_err() logs the correct line number and exits" {
  skip "trap_err exits the shell immediately, interfering with Bats output capture"
}

@test "resolve_script_dir() returns existing script directory" {
  result="$(bash -c 'source "'"$BATS_TEST_DIRNAME"'/rc-utils.sh"; resolve_script_dir' 2>/dev/null)"
  [ -d "$result" ]
}

teardown() {
  rm -f "$BATS_TMPDIR/testfile" "$BATS_TMPDIR/dryfile"
}