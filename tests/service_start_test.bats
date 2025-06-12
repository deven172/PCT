#!/usr/bin/env bats

load './helpers.bash'

setup() {
  setup_stubs
  stub_groovy_success
  touch app.env
  mkdir -p stacks
  touch stacks/test-compose.yml
}

@test "service_start.sh requires arguments" {
  run bash ./service_start.sh
  [ "$status" -eq 1 ]
}

@test "service_start.sh fails without docker" {
  run bash ./service_start.sh test
  [ "$status" -ne 0 ]
  [[ "$output" == *"docker"* ]]
}

@test "service_start.sh missing compose file" {
  stub_docker_success
  run bash ./service_start.sh missing
  [ "$status" -ne 0 ]
}

@test "service_start.sh succeeds" {
  stub_docker_success
  run bash ./service_start.sh test
  [ "$status" -eq 0 ]
}

