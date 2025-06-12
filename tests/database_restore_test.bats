#!/usr/bin/env bats

load './helpers.bash'

setup() {
  setup_stubs
  touch app.env db.env
  mkdir -p stacks
  touch stacks/sqlserver-compose.yml
}

@test "database_restore.sh fails without docker" {
  run env PATH="$STUB_BIN:$PATH" bash ./database_restore.sh -f /tmp -d hub -y
  [ "$status" -ne 0 ]
  [[ "$output" == *"docker"* ]]
}

@test "database_restore.sh fails for missing folder" {
  stub_docker_success
  stub_curl_success
  run env PATH="$STUB_BIN:$PATH" bash -c 'printf "missing\nN\nhub\n" | bash ./database_restore.sh -f missing -d hub -y'
  [ "$status" -ne 0 ]
}

@test "database_restore.sh fails for invalid db" {
  stub_docker_success
  stub_curl_success
  mkdir -p /mnt/dbbackup/default
  touch /mnt/dbbackup/default/hub.bak
  run env PATH="$STUB_BIN:$PATH" bash -c 'printf "default\nN\nfoo\n" | bash ./database_restore.sh -f default -d foo -y'
  [ "$status" -ne 0 ]
  rm -rf /mnt/dbbackup/default
}

@test "database_restore.sh succeeds" {
  stub_docker_success
  stub_curl_success
  mkdir -p /mnt/dbbackup/default
  touch /mnt/dbbackup/default/hub.bak
  run env PATH="$STUB_BIN:$PATH" bash -c 'printf "default\nN\nhub\n" | bash ./database_restore.sh -f default -d hub -y'
  [ "$status" -eq 0 ]
  rm -rf /mnt/dbbackup/default
}

