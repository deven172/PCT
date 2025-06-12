setup_stubs() {
  STUB_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$STUB_BIN"
  PATH="$STUB_BIN:$PATH"
  export STUB_BIN
}

stub_docker_success() {
  cat <<'SH' > "$STUB_BIN/docker"
#!/usr/bin/env bash
if [[ $1 == wait ]]; then exit 0; fi
exit 0
SH
  chmod +x "$STUB_BIN/docker"
}

stub_docker_wait_fail() {
  cat <<'SH' > "$STUB_BIN/docker"
#!/usr/bin/env bash
if [[ $1 == wait ]]; then exit 1; fi
exit 0
SH
  chmod +x "$STUB_BIN/docker"
}

stub_curl_success() {
  cat <<'SH' > "$STUB_BIN/curl"
#!/usr/bin/env bash
cp "${@: -1}" "${@: -3:1}" # naive copy from FILE://src to dest
SH
  chmod +x "$STUB_BIN/curl"
}

stub_groovy_success() {
  cat <<'SH' > "$STUB_BIN/groovy"
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$STUB_BIN/groovy"
}

