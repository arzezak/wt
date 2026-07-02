# 🌳💻 wt

A small Crystal CLI for managing git worktrees.

## Who this is for

wt is for people who want to create, switch between, and remove worktrees by hand from the terminal, and keep an eye on what exists. If you want manual control over your worktrees rather than delegating that to automation, wt is for you.

## Install

Requires [Crystal](https://crystal-lang.org/) (`brew install crystal`).

```sh
make install
```

Add to your `.zshrc`:

```sh
eval "$(command wt init zsh)"
```

Reload your shell (`exec zsh`) and you're set. `make uninstall` removes the binary.

## Usage

Switch to a worktree (exact or unique-prefix match, tab-completes):

```sh
wt [name]
wt cd <name>
wt cd main    # back to the main worktree (also matches the main branch name)
wt cd -       # back to the previous worktree
```

Create a worktree, optionally from a base ref:

```sh
wt new <branch> [base]
```

When the branch exists, `wt new` checks it out into a new worktree. When the branch is new, it creates it from `[base]`, or from the current `HEAD` if no base is provided. Either way, it switches into the worktree when it finishes.

Remove a worktree (branch preserved):

```sh
wt rm [name]
```

List worktrees:

```sh
wt ls
```

Other commands:

```sh
wt help
wt --version
```

### Resolution

When you pass a name, `wt` resolves it directly: exact match first, then unique prefix, then error with candidates.

When you omit the name, `wt` lists the available worktrees. `wt cd main` returns to the main worktree, and `wt cd -` returns to the worktree you came from.

### Tab completion

Tab completion is set up automatically by `wt init zsh`. It completes:

- `wt cd <tab>` / `wt rm <tab>`: worktree names
- `wt new <tab>`: branch names
- `wt new <branch> <tab>`: branch/ref names for the base

## Configuration

Per-repo `.wt.yml` (committed, shared with the team) with an optional `.wt.local.yml` override (gitignored, personal). Global defaults in `~/.config/wt/config.yml`. Merge order: global, repo, local.

```yaml
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

Each command is announced on stderr with a 🌳 prefix (as are `copy` files) so it's easy to tell wt's own output apart from the command's.

Each command runs with `WT_WORKTREE_NAME` set to the worktree's directory name (e.g. `feature-foo`), useful for isolating per-worktree resources like a database name.

For example, giving each worktree its own Rails development/test database:

```yaml
after_create:
  - |
    cat > .env.local << ENV
    DB_DATABASE=${WT_WORKTREE_NAME}_development
    DB_TEST_DATABASE=${WT_WORKTREE_NAME}_test
    ENV
  - bundle install
  - yarn install
  - bin/rails db:create db:schema:load
```

### `--no-hooks`

Skip all copy and after_create steps on `wt new`.

### Trust model

`.wt.yml` can be committed to a repo, and `after_create` runs arbitrary shell commands. This is the same trust model as Makefiles and npm scripts: review `.wt.yml` before running `wt new` in an untrusted repo, or pass `--no-hooks`.

## Shell integration

### The cd problem

A compiled binary can't `cd` your shell (it's a child process). So `wt` is a **binary + thin shim**, like zoxide or rbenv:

- The **binary** holds all logic (resolve paths, create/remove worktrees, format output).
- A tiny **shell function** calls the binary and `eval`s its stdout for navigation commands.

Both are named `wt`. The function shadows the binary for interactive use and delegates with `command wt` (which bypasses functions and runs the executable on PATH).

### Stdout protocol

The binary emits two kinds of output on stdout:

1. **Directives** the shim `eval`s (e.g. `cd <path>`)
2. **Plain text** the shim prints as-is (ls, help, messages)

Errors and human messages go to stderr so they never get `eval`d and hook output (bundle install, etc.) streams live.

## Worktree conventions

- Worktrees live in `<repo>/.worktrees/<branch>`.
- `/` in branch names becomes `-` for the directory (`feature/foo` becomes `.worktrees/feature-foo`).
- `.worktrees/` is added to `.git/info/exclude` (local-only, never the committed `.gitignore`).

## Development

```sh
make build
make test
```

`make test` runs `crystal spec`.
