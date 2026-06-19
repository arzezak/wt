require "./wt/result"
require "./wt/git"
require "./wt/repo"
require "./wt/resolver"
require "./wt/picker"
require "./wt/config"
require "./wt/completion"
require "./wt/commands/*"

module Wt
  VERSION = "0.1.0"

  HELP = <<-HELP
  wt — git worktrees, fuzzily

  USAGE
    wt [cd] [name]          switch to a worktree (fzf-pick or resolve by name)
    wt new <branch> [base]  create/checkout a worktree, cd into it
    wt rm [name]            remove a worktree (branch preserved)
    wt ls                   list all worktrees
    wt help                 this text

  WHERE
    worktrees live in <repo>/.worktrees/<branch> (auto git-ignored; slashes become dashes)

  cd
    bare "wt" is "wt cd". with a name, resolves by exact match then unique prefix.
    with no name, fzf-picks if available, else lists worktrees.
    errors out if the repo only has one worktree (nothing to switch to).

  new
    branch exists: checks it out into the new worktree
    branch is new: creates it from <base> (default: current HEAD)
    then cd into the worktree.
    note: git refuses a branch already checked out elsewhere (e.g. main).
    pass --no-hooks to skip copy + after_create steps.

  rm
    removes the picked worktree but preserves its branch.
    refuses the main worktree; git refuses if there are uncommitted changes.
  HELP

  def self.run(args : Array(String)) : Nil
    result = dispatch(args)
    result.render(STDOUT)
  rescue ex
    STDERR.puts "wt: #{ex.message}"
    exit 1
  end

  private def self.dispatch(args : Array(String)) : Result
    subcommand = args.empty? ? "cd" : args.shift

    case subcommand
    when "cd"
      Commands::Cd.run(args.first?)
    when "new"
      dispatch_new(args)
    when "rm"
      Commands::Rm.run(args.first?)
    when "ls", "list"
      Commands::Ls.run
    when "help", "-h", "--help"
      Result.print(HELP)
    when "--version", "-v"
      Result.print("wt #{VERSION}")
    when "__complete"
      Completion.complete(args.first? || "subcommands")
    when "init"
      Completion.init_script(args.first? || "zsh")
    else
      STDERR.puts "wt: unknown subcommand '#{subcommand}'"
      STDERR.puts HELP
      exit 1
    end
  end

  private def self.dispatch_new(args : Array(String)) : Result
    hooks = true
    branch = nil
    base = nil

    args.each do |arg|
      if arg == "--no-hooks"
        hooks = false
      elsif branch.nil?
        branch = arg
      else
        base = arg
      end
    end

    unless branch
      STDERR.puts "wt: usage: wt new <branch> [base] [--no-hooks]"
      exit 1
    end

    Commands::New.run(branch, base, hooks: hooks)
  end
end

Wt.run(ARGV.to_a)
