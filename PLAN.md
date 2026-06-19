# wt — a one-stop shop for git worktrees

A small Crystal CLI for managing git worktrees, fuzzily. A rewrite of an existing ~140-line zsh function (`dotfiles/zsh/.../functions/wt`), for fun and as a real Crystal project. The zsh version is the working spec; this repo is the compiled successor.

## Why Crystal

Ruby-ish syntax, compiles to a single fast binary, real `OptionParser`, and actual specs. Good first-project size: small enough to finish, real enough to hit interesting bits (shelling out, output parsing, the cd-shim trick).

## The one hard constraint: a binary can't `cd` your shell

A compiled binary is a child process; when it exits, the parent shell's cwd is unchanged. `wt cd` / `wt new` only work today because `wt` is a _shell function_. So the design is **binary + thin shim**, exactly like zoxide/fzf:

- The **binary** holds all logic (resolve paths, create/remove worktrees, drive fzf, format output).
- A tiny **`wt` shell function** calls the binary and `eval`s its stdout for navigation commands.

### Naming: one name for both (the rbenv/pyenv pattern)

We want `wt` as the user-facing command everywhere, friendly ergonomics, one name to remember. So **both the function and the binary are named `wt`**. The function shadows the binary for interactive use and delegates to the real binary with `command wt`, which bypasses functions/aliases and runs the executable on PATH, so no infinite recursion.

This is exactly how `rbenv`/`pyenv` work: a shell function named `rbenv` intercepts the subcommands that must mutate the shell and passes the rest through with `command rbenv`. `which wt` shows the function; the binary still lives at `~/.local/bin/wt`.

(Alternative if the `command` indirection feels too magic: name the binary `wt-bin` and keep the function `wt`, the zoxide/thefuck "engine + wrapper" style. We're choosing the same-name approach for ergonomics.)

### The shim protocol

Decide this early, it's the one bit that bites people.

The binary speaks two kinds of result on **stdout**:

1. **Directive lines** the shim must `eval`, prefixed so they're unambiguous:
   - `cd <path>` — change directory (cd, new)
2. **Plain output** for everything else (ls, help, messages), printed as-is.

Errors and human messages go to **stderr** so they never get `eval`d (and so `bundle install` / hook output streams live instead of being captured).

Shim (lives in dotfiles, replaces the current `wt` function):

```zsh
wt() {
  local output
  output=$(command wt "$@") || return   # real binary on PATH, not this function
  if [[ "$output" == cd\ * ]]; then
    eval "$output"
  elif [[ -n "$output" ]]; then
    print -r -- "$output"
  fi
}
```

Refine as needed (e.g. binary could emit multiple directives; for now a single leading `cd <path>` is enough).

## Behaviors to port (this is the spec + test checklist)

From the working zsh version:

- **Location**: worktrees live in `<repo>/.worktrees/<branch>`.
- **Branch sanitizing**: `/` in branch names becomes `-` for the dir (`feature/foo` becomes `.worktrees/feature-foo`).
- **Auto-ignore**: add `.worktrees/` to `.git/info/exclude` (local-only, never the committed `.gitignore`) so `git status` stays clean. Idempotent.
- **Main-repo resolution**: derive the main worktree from `git rev-parse --path-format=absolute --git-common-dir` then parent dir. Works the same whether invoked from main or from inside a worktree.
- **`cd` / default**: bare `wt` = `wt cd`. With a name, resolve directly (exact/unique-prefix) and `cd` in, tab-completes. With no name, fzf-pick if fzf is present, else print the list (see Completion below). If the repo has only one worktree, print a message instead of a silent no-op.
- **`new <branch> [base]`**: auto-detect:
  - branch exists: check it out into the new worktree
  - branch is new: create it from `<base>` (default current HEAD)
  - if the worktree dir already exists, just `cd` into it
  - then `cd` into the worktree
  - note: git refuses a branch already checked out elsewhere (e.g. main), let that error surface.
- **`rm [name]`**: resolve by name (tab-completes) or fzf-pick when no arg, `git worktree remove`, **branch preserved**. Refuse the main worktree. git refuses if there are uncommitted changes, let that surface.
- **`ls`**: list this repo's worktrees. Opportunity to improve on raw `git worktree list`: strip the common path prefix, show `<branch> + sha` scoped to this repo (the zsh version just shelled out raw).
- **`help` / `-h` / `--help`**: usage text. Unknown subcommand: error + help, exit non-zero.

## Completion (and making fzf optional)

We want shell completion for `wt`'s arguments, and good completion means you can `wt cd <tab>` instead of fuzzy-picking, so **fzf becomes a convenience, not a dependency**.

### What completes where

- `wt cd <tab>` / `wt rm <tab>`: existing **worktree names** (the `<branch>` dir names under `.worktrees`, not full paths).
- `wt new <tab>`: existing **branch names** (the resume-a-branch case).
- `wt new <branch> <tab>`: **branch/ref names** for the optional `[base]`.
- first arg: subcommand names (`cd new rm ls help`).

### How the data gets to the shell

Don't hardcode candidates in the completion script, generate them from the binary, so they're always current. The cobra/rbenv approach:

- A hidden `wt __complete <kind>` command prints newline-separated candidates (`wt __complete worktrees`, `wt __complete branches`, `wt __complete refs`).
- A `wt completions <shell>` command prints the static completion script (like `zoxide init` / `rbenv init`). That script calls `wt __complete ...` dynamically as you tab.
- Ship the generated script via dotfiles (write it to the zsh `completions` dir, or `eval` it in `.zshrc`).

### fzf as optional fallback

Decouple resolution from fzf so the tool works with neither fzf nor tab:

- **arg given** (`wt cd foo`): resolve directly: exact match, else unique prefix match, else error listing candidates. No fzf needed.
- **no arg** (`wt cd`): if fzf is on PATH, interactive-pick; otherwise print the worktree list and a "pass a name (tab-completes)" hint, exit non-zero.

So the dependency story becomes: tab-completion is the primary path, fzf is a nice no-arg picker when present, and a plain list is the floor when neither is.

## Architecture

Shell out, don't reimplement. `Process.run` to `git` and `fzf`; no git library.

```
src/
  wt.cr            # entrypoint: OptionParser, subcommand dispatch
  wt/
    git.cr         # thin wrapper over `git worktree ...`, rev-parse helpers
    repo.cr        # main-repo resolution, worktree root, ignore handling
    resolver.cr    # name -> worktree (exact/unique-prefix); candidate lists
    picker.cr      # optional fzf integration (feed list, parse selection)
    completion.cr  # `__complete <kind>` data + `completions <shell>` script
    commands/
      cd.cr
      new.cr
      rm.cr
      ls.cr
spec/
  ...              # one spec per command + repo/git helpers
```

- **Result/directive type**: a small struct the commands return, e.g. `Result.new(cd: path)` or `Result.new(stdout: text)`. The entrypoint renders it to the shim protocol. Keeps commands testable without touching real stdout.
- **`Process.run`** with captured output for git (and fzf when used). fzf needs a tty for its UI but reads candidates from stdin and writes the selection to stdout, same as the zsh `$(... | fzf)` pattern. Detect fzf on PATH; degrade gracefully when absent.

## Build sequence

1. `shards init` skeleton, `shard.yml`, `.gitignore` (`/bin/`, `/lib/`, `*.dwarf`), CI later.
2. `git.cr` + `repo.cr`: path resolution + `.worktrees/` ignore. Spec against a throwaway repo created in a temp dir.
3. `ls` first: read-only, easy win, exercises git wrapper + output formatting.
4. `new`: the meatiest: branch detection, base, dir-exists, cd directive.
5. `resolver.cr`: name to worktree (exact/unique-prefix) + candidate lists. This is the fzf-free resolution path that `cd`/`rm` build on.
6. `cd`: direct resolve + single-worktree message; fzf only as no-arg fallback.
7. `rm`: resolve/picker + main-repo guard + branch-preserved message.
8. `OptionParser` dispatch + `help` + unknown-subcommand.
9. **Completion**: `__complete <kind>` (worktrees/branches/refs) + `completions <shell>` script. Makes tab the primary path, fzf optional.
10. **Config + hooks**: `Config` type (YAML, merge global/repo/local), then `copy` and `after_create` wired into `new`, plus `--no-hooks`. Build this after `new` works bare, so the hooks layer on a known-good create.
11. The shim + completion script. Wire into dotfiles, swap the stow/alias over once happy. Until then, keep the zsh `wt` as-is so nothing breaks.

## Configuration & hooks

The feature that justifies the rewrite. A fresh worktree is rarely usable straight away: it's missing gitignored files (`.env`, `config/master.key`) and needs setup (`bundle install`, `yarn install`, `bin/setup`). `wt new` should optionally do this for you.

### Config file

Per-repo, since worktree needs are per-repo. Look for `.wt.yml` (or `wt.yml`) in the repo root. Decisions to make:

- **Committed vs local**: a committed `.wt.yml` shares setup with the team (everyone needs `bundle install`); a local override (`.git/wt.yml` or `.wt.local.yml`, git-ignored) covers personal bits. Support a committed file with an optional local override merged on top.
- **Global defaults**: `~/.config/wt/config.yml` for cross-repo defaults (merge order: global, repo, local).

Sketch:

```yaml
# .wt.yml
copy: # files to copy from main worktree into the new one
  - .env
  - .env.local
  - config/master.key
after_create: # commands run in the new worktree, in order
  - bundle install
  - yarn install
```

### Hook semantics

- **`copy`**: copy listed paths from the **main worktree** into the new one (these are gitignored, so they don't come across with the checkout). Skip missing sources with a warning, don't fail the whole create.
- **`after_create`**: run each command in the new worktree's dir, in order, streaming output. Stop on first non-zero exit and report which step failed, but the worktree is already created, so leave it in place for the user to fix (don't auto-rollback).
- Run hooks **after** `cd` is resolved but report them to stderr so they never pollute the `cd` directive on stdout.
- **`--no-hooks` flag** on `wt new` to skip everything (fast path when you just want the checkout).
- Possible later: `pre_remove` hook for `wt rm` (e.g. confirm, archive).

### Implementation notes

- Crystal stdlib `YAML` for parsing; a `Config` type with merge logic.
- Hooks shell out via `Process.run` with the worktree dir as cwd, inheriting stdout/stderr so `bundle install` output streams live.
- Order in `wt new`: create worktree, copy files, run `after_create`, emit `cd` directive. (User lands in a ready-to-work dir.)

## Notes / open questions

- Toolchain not installed yet: `brew install crystal` (`crystal` + `shards`).
- Distribution via dotfiles: build locally, symlink/stow the binary into `~/.local/bin` (already on PATH), ship the shim as the zsh function.
- Possible later: launch a claude session in the new worktree (the original motivation), but keep `wt` worktree-only; that belongs in a separate composable command.
- Reference implementation: `arzezak/dotfiles` then `zsh/dot-config/zsh/functions/wt`.
