module Wt
  class CLI
    VERSION = "0.1.0"

    HELP = <<-HELP
    wt — git worktrees

    USAGE
      wt [cd] [name]          switch to a worktree (resolve by name, tab-completes)
      wt new <branch> [base]  create/checkout a worktree, cd into it
      wt rm [name]            remove a worktree (branch preserved)
      wt ls                   list all worktrees
      wt help                 this text

    WHERE
      worktrees live in <repo>/.worktrees/<branch> (auto git-ignored; slashes become dashes)

    cd
      bare "wt" is "wt cd". with a name, resolves by exact match then unique prefix.
      with no name, lists available worktrees.
      "wt cd main" returns to the main worktree (also matches the main branch name).
      "wt cd -" returns to the previous worktree.
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

    def run(args : Array(String)) : Nil
      result = dispatch(args)
      result.render(STDOUT)
    rescue ex
      Log.puts "#{ex.message}"
      exit 1
    end

    private def dispatch(args : Array(String)) : Result
      subcommand = args.empty? ? "cd" : args.shift

      case subcommand
      when "help", "-h", "--help"
        Result.print(HELP)
      when "--version", "-v"
        Result.print("wt #{VERSION}")
      when "init"
        Completion.init_script(args.first? || "zsh")
      when "cd", "new", "rm", "ls", "list", "__complete"
        dispatch_repo_command(subcommand, args)
      else
        raise "unknown subcommand '#{subcommand}'\n#{HELP}"
      end
    end

    private def dispatch_repo_command(subcommand : String, args : Array(String)) : Result
      git = Git.new
      repo = Repo.new(git)
      resolver = Resolver.new(repo, git)

      case subcommand
      when "cd"
        Commands::Cd.new(resolver, repo).run(args.first?)
      when "new"
        dispatch_new(git, repo, args)
      when "rm"
        Commands::Rm.new(resolver, git, repo).run(args.first?)
      when "ls", "list"
        Commands::Ls.new(git, repo).run
      when "__complete"
        Completion.new(git, resolver).complete(args.first? || "subcommands")
      else
        raise "BUG: unhandled subcommand '#{subcommand}'"
      end
    end

    private def dispatch_new(git : Git, repo : Repo, args : Array(String)) : Result
      hooks = !args.delete("--no-hooks")
      branch = args.shift?
      base = args.shift?
      raise "usage: wt new <branch> [base] [--no-hooks]" unless branch

      Commands::New.new(git, repo).run(branch, base, hooks: hooks)
    end
  end
end
