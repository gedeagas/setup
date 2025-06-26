#!/usr/bin/env bats

# Load the script
setup() {
  # Use a temp HOME to avoid polluting real user env
  export TEST_HOME="$BATS_TMPDIR/fakehome"
  mkdir -p "$TEST_HOME"
  export HOME="$TEST_HOME"
  # Create a dummy .sdkman dir for sdkman tests
  mkdir -p "$HOME/.sdkman/bin"
  # Create a dummy sdkman-init.sh
  echo "#!/bin/bash" > "$HOME/.sdkman/bin/sdkman-init.sh"
  chmod +x "$HOME/.sdkman/bin/sdkman-init.sh"
  # Source the script
  source ./setup.sh
}

@test "is_nvm_installed returns false if .nvm does not exist" {
  rm -rf "$HOME/.nvm"
  run is_nvm_installed
  [ "$status" -ne 0 ]
}

@test "is_nvm_installed returns true if .nvm exists" {
  mkdir -p "$HOME/.nvm"
  run is_nvm_installed
  [ "$status" -eq 0 ]
}

@test "is_rbenv_installed returns false if rbenv not in PATH" {
  PATH="/usr/bin"
  run is_rbenv_installed
  [ "$status" -ne 0 ]
}

@test "is_rbenv_installed returns true if rbenv in PATH" {
  mkdir -p "$BATS_TMPDIR/bin"
  echo -e '#!/bin/sh\necho rbenv' > "$BATS_TMPDIR/bin/rbenv"
  chmod +x "$BATS_TMPDIR/bin/rbenv"
  PATH="$BATS_TMPDIR/bin:$PATH"
  run is_rbenv_installed
  [ "$status" -eq 0 ]
}

@test "is_sdkman_installed returns false if .sdkman does not exist" {
  rm -rf "$HOME/.sdkman"
  run is_sdkman_installed
  [ "$status" -ne 0 ]
}

@test "is_sdkman_installed returns true if .sdkman exists" {
  mkdir -p "$HOME/.sdkman"
  run is_sdkman_installed
  [ "$status" -eq 0 ]
}

@test "is_nvm_version_installed returns true if nvm ls outputs version" {
  nvm() { echo "-> v18.20.7"; }
  export -f nvm
  run is_nvm_version_installed "18.20.7"
  [ "$status" -eq 0 ]
}

@test "is_nvm_version_installed returns false if nvm ls does not output version" {
  nvm() { echo "-> v16.0.0"; }
  export -f nvm
  run is_nvm_version_installed "18.20.7"
  [ "$status" -ne 0 ]
}

@test "is_rbenv_version_installed returns true if rbenv versions outputs version" {
  rbenv() { if [ "$1" = "versions" ]; then echo "3.1.6"; fi; }
  export -f rbenv
  run is_rbenv_version_installed "3.1.6"
  [ "$status" -eq 0 ]
}

@test "is_rbenv_version_installed returns false if rbenv versions does not output version" {
  rbenv() { if [ "$1" = "versions" ]; then echo "2.7.0"; fi; }
  export -f rbenv
  run is_rbenv_version_installed "3.1.6"
  [ "$status" -ne 0 ]
}

@test "is_sdkman_java_installed returns true if sdk list java outputs version" {
  sdk() { if [ "$1" = "list" ] && [ "$2" = "java" ]; then echo "17.0.14-zulu"; fi; }
  export -f sdk
  run is_sdkman_java_installed "17.0.14-zulu"
  [ "$status" -eq 0 ]
}

@test "is_sdkman_java_installed returns false if sdk list java does not output version" {
  sdk() { if [ "$1" = "list" ] && [ "$2" = "java" ]; then echo "11.0.0-zulu"; fi; }
  export -f sdk
  run is_sdkman_java_installed "17.0.14-zulu"
  [ "$status" -ne 0 ]
}

# Wrapper for prompt_and_set_flag to capture variable value
prompt_and_set_flag_wrapper() {
  INSTALL_TEST=false
  prompt_and_set_flag "Test?" INSTALL_TEST
  echo "$INSTALL_TEST"
}

@test "prompt_and_set_flag does not set variable to true on n" {
  run prompt_and_set_flag_wrapper <<< "n"
  [ "${lines[0]}" != "true" ]
}