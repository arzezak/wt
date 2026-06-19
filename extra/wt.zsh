wt() {
  local output
  output=$(command wt "$@") || return

  if [[ "$output" == cd\ * ]]; then
    eval "$output"
  elif [[ -n "$output" ]]; then
    print -r -- "$output"
  fi
}
