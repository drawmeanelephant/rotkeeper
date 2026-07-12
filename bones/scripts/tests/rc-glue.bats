#!/usr/bin/env bats

setup() {
  export ROOT_DIR="$BATS_TEST_DIRNAME/../../.."
  export BONES_DIR="$ROOT_DIR/bones"
  export SCRIPT_DIR="$BONES_DIR/scripts"
  export TMP_DIR=$(mktemp -d)
  mkdir -p "$TMP_DIR/content/test_dir"
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "rc-glue handles spaces and apostrophes in frontmatter title" {
  mkdir -p "$TMP_DIR/content/test ' space"
  touch "$TMP_DIR/content/test ' space/doc.md"

  run "$SCRIPT_DIR/rc-glue.sh" --force

  [ "$status" -eq 0 ]
  # We just want to check it runs without failing on bash interpolation
}
