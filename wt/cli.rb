module Wt
  class CLI
    VERSION = "0.1.0"

    HELP = <<~HELP
      wt — git worktrees

      USAGE
        wt [cd] [name]          switch to a worktree (resolve by name, tab-completes)
        wt new <branch> [base]  create/checkout a worktree, cd into it
        wt rm [name]            remove a worktree (branch preserved)
        wt ls [-l]              list all worktrees (-l/--long adds the HEAD sha)
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

    def initialize
      @git = nil
      @resolver = nil
    end

    def run(args)
      dispatch(args).render($stdout)
    rescue => e
      Log.puts(e.message)
      exit 1
    end

    private

    def dispatch(args)
      subcommand = args.empty? ? "cd" : args.shift

      case subcommand
      when "help", "-h", "--help"
        Result.print(HELP)
      when "--version", "-v"
        Result.print("wt #{VERSION}")
      when "init"
        Completion.init_script(args.first || "zsh")
      when "cd"
        Commands::Cd.new(resolver).run(args.first)
      when "new"
        dispatch_new(args)
      when "rm"
        Commands::Rm.new(resolver, git).run(args.first)
      when "ls", "list"
        dispatch_ls(args)
      when "__complete"
        Completion.new(git, resolver).complete(args.first || "subcommands")
      else
        raise "unknown subcommand '#{subcommand}'\n#{HELP}"
      end
    end

    def dispatch_ls(args)
      short = args.delete("-l")
      long = args.delete("--long")
      unknown = args.find { |arg| arg.start_with?("-") }
      raise "unknown flag '#{unknown}' for ls" if unknown

      Commands::Ls.new(git).run(long: !(short.nil? && long.nil?))
    end

    def dispatch_new(args)
      hooks = args.delete("--no-hooks").nil?
      branch = args.shift
      base = args.shift
      raise "usage: wt new <branch> [base] [--no-hooks]" unless branch

      Commands::New.new(git, Repo.new(git)).run(branch, base, hooks: hooks)
    end

    def git
      @git ||= Git.new
    end

    def resolver
      @resolver ||= Resolver.new(git)
    end
  end
end
