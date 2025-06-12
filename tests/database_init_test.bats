#!/usr/bin/env bats

load './helpers.bash'

setup() {
  setup_stubs
  touch db.env
  mkdir -p stacks
  touch stacks/sqlserver-compose.yml
}

@test "database_init.sh fails without docker" {
  run env PATH="$STUB_BIN:$PATH" bash ./database_init.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"docker"* ]]
}

@test "database_init.sh fails on container error" {
  stub_docker_wait_fail
  run bash ./database_init.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"sqlserver.configurator"* ]]
}

@test "database_init.sh succeeds" {
  stub_docker_success
  run bash ./database_init.sh
  [ "$status" -eq 0 ]
}

