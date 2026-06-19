module Wt
  module Completion
    def self.complete(kind : String) : Result
      candidates = case kind
                   when "worktrees"
                     Resolver.worktree_names
                   when "branches"
                     branch_names
                   when "refs"
                     ref_names
                   when "subcommands"
                     ["cd", "new", "rm", "ls", "help"]
                   else
                     [] of String
                   end
      Result.print(candidates.join("\n"))
    end

    def self.completions_script(shell : String) : Result
      case shell
      when "zsh"
        Result.print(zsh_completion_script)
      else
        STDERR.puts "wt: unsupported shell '#{shell}' (available: zsh)"
        Result.none
      end
    end

    private def self.branch_names : Array(String)
      output = Git.run("branch", "--format=%(refname:short)")
      output.split("\n").reject(&.empty?)
    end

    private def self.ref_names : Array(String)
      output = Git.run("for-each-ref", "--format=%(refname:short)", "refs/heads/", "refs/tags/", "refs/remotes/")
      output.split("\n").reject(&.empty?)
    end

    private def self.zsh_completion_script : String
      <<-'ZSH'
      #compdef wt

      _wt() {
        local -a subcommands=(
          'cd:switch to a worktree'
          'new:create a worktree'
          'rm:remove a worktree'
          'ls:list worktrees'
          'help:show help'
        )

        if (( CURRENT == 2 )); then
          _describe 'subcommand' subcommands
          return
        fi

        case "${words[2]}" in
          cd|rm)
            local -a worktrees
            worktrees=(${(f)"$(command wt __complete worktrees)"})
            _describe 'worktree' worktrees
            ;;
          new)
            if (( CURRENT == 3 )); then
              local -a branches
              branches=(${(f)"$(command wt __complete branches)"})
              _describe 'branch' branches
            elif (( CURRENT == 4 )); then
              local -a refs
              refs=(${(f)"$(command wt __complete refs)"})
              _describe 'ref' refs
            fi
            ;;
        esac
      }

      _wt "$@"
      ZSH
    end
  end
end
