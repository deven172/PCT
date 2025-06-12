#!/usr/bin/env bats

load './helpers.bash'

setup() {
  setup_stubs
  touch helper/enable_disable_service.groovy
}

@test "service_scenario_apply.sh requires argument" {
  run bash ./service_scenario_apply.sh
  [ "$status" -eq 1 ]
}

@test "service_scenario_apply.sh file not found" {
  run bash ./service_scenario_apply.sh /tmp/does-not-exist
  [ "$status" -eq 1 ]
}

@test "service_scenario_apply.sh empty file" {
  touch empty.txt
  run bash ./service_scenario_apply.sh empty.txt
  [ "$status" -eq 1 ]
  rm empty.txt
}

@test "service_scenario_apply.sh fails without groovy" {
  echo "serviceA" > list.txt
  run env PATH="$STUB_BIN:$PATH" bash ./service_scenario_apply.sh list.txt
  [ "$status" -ne 0 ]
  rm list.txt
}

@test "service_scenario_apply.sh succeeds" {
  stub_groovy_success
  echo "svc" > list.txt
  run bash ./service_scenario_apply.sh list.txt
  [ "$status" -eq 0 ]
  rm list.txt
}

