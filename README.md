# wt

A small Crystal CLI for managing git worktrees, fuzzily.

## Usage

```
wt              # fuzzy-pick a worktree (fzf) or list them
wt cd <name>    # cd into a worktree (exact or unique-prefix match)
wt new <branch> [base]  # create a worktree, optionally from a base ref
wt rm [name]    # remove a worktree (branch preserved)
wt ls           # list worktrees
```

### Resolution

When you pass a name, `wt` resolves it directly: exact match first, then unique prefix, then error with candidates. No fzf needed.

When you omit the name, `wt` uses fzf if available, otherwise prints the list with a hint to pass a name or use tab completion.

### Tab completion

```sh
# Add to .zshrc
eval "$(wt completions zsh)"
```

Completions are generated dynamically from the binary:

- `wt cd <tab>` / `wt rm <tab>`: worktree names
- `wt new <tab>`: branch names
- `wt new <branch> <tab>`: branch/ref names for the base

## Configuration

Per-repo `.wt.yml` (committed, shared with the team) with an optional `.wt.local.yml` override (gitignored, personal). Global defaults in `~/.config/wt/config.yml`. Merge order: global, repo, local.

```yaml
# .wt.yml
copy:
  - .env
  - .env.local
  - config/master.key

after_create:
  - bundle install
  - yarn install
```

### `copy`

Files to copy from the main worktree into the new one. These are typically gitignored, so they don't come across with the checkout. Missing sources are skipped with a warning.

### `after_create`

Commands run in the new worktree's directory, in order, streaming output. Stops on first non-zero exit. The worktree is already created, so it stays in place for you to fix manually.

### `--no-hooks`

Skip all copy and after_create steps on `wt new`.

## How it works

### The cd problem

A compiled binary can't `cd` your shell (it's a child process). So `wt` is a **binary + thin shim**, like zoxide or rbenv:

- The **binary** holds all logic (resolve paths, create/remove worktrees, drive fzf, format output).
- A tiny **shell function** calls the binary and `eval`s its stdout for navigation commands.

Both are named `wt`. The function shadows the binary for interactive use and delegates with `command wt` (which bypasses functions and runs the executable on PATH).

### Shim

```zsh
wt() {
  local output
  output=$(command wt "$@") || return

  if [[ "$output" == cd\ * ]]; then
    eval "$output"
  elif [[ -n "$output" ]]; then
    print -r -- "$output"
  fi
}
```

### Stdout protocol

The binary emits two kinds of output on stdout:

1. **Directives** the shim `eval`s (e.g. `cd <path>`)
2. **Plain text** the shim prints as-is (ls, help, messages)

Errors and human messages go to stderr so they never get `eval`d and hook output (bundle install, etc.) streams live.

## Worktree conventions

- Worktrees live in `<repo>/.worktrees/<branch>`.
- `/` in branch names becomes `-` for the directory (`feature/foo` becomes `.worktrees/feature-foo`).
- `.worktrees/` is added to `.git/info/exclude` (local-only, never the committed `.gitignore`).

## Architecture

Shell out, don't reimplement. `Process.run` to `git` and `fzf`; no git library.

```
src/
  wt.cr              # entrypoint, subcommand dispatch
  wt/
    git.cr           # thin wrapper over git worktree, rev-parse helpers
    repo.cr          # main-repo resolution, worktree root, ignore handling
    resolver.cr      # name -> worktree (exact/unique-prefix), candidate lists
    picker.cr        # optional fzf integration
    completion.cr    # __complete <kind> + completions <shell> script
    commands/
      cd.cr
      new.cr
      rm.cr
      ls.cr
spec/
  ...                # one spec per command + repo/git helpers
```

Commands return a small `Result` struct (e.g. `Result.new(cd: path)` or `Result.new(stdout: text)`). The entrypoint renders it to the shim protocol, keeping commands testable without touching real stdout.

## Install

Toolchain: `brew install crystal` (provides `crystal` + `shards`).

Build locally, symlink/stow the binary into `~/.local/bin` (already on PATH), ship the shim as a zsh function in your dotfiles.

## Why Crystal

Ruby-ish syntax, compiles to a single fast binary, real `OptionParser`, and actual specs. Good first-project size: small enough to finish, real enough to hit interesting bits (shelling out, output parsing, the cd-shim trick).
