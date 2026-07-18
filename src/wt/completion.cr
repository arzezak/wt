module Wt
  class Completion
    def initialize(@git : Git, @resolver : Resolver)
    end

    def complete(kind : String) : Result
      candidates = case kind
                   when "worktrees"
                     @resolver.worktree_names
                   when "cd_targets"
                     @resolver.worktree_names + ["main"]
                   when "branches"
                     git_lines("branch", "--format=%(refname:short)")
                   when "refs"
                     git_lines("for-each-ref", "--format=%(refname:short)", "refs/heads/", "refs/tags/", "refs/remotes/")
                   when "subcommands"
                     ["cd", "new", "rm", "ls", "help"]
                   else
                     [] of String
                   end
      Result.print(candidates.join("\n"))
    end

    def self.init_script(shell : String) : Result
      case shell
      when "zsh"
        Result.print(zsh_init_script)
      else
        Log.puts "unsupported shell '#{shell}' (available: zsh)"
        Result.none
      end
    end

    private def git_lines(*args : String) : Array(String)
      @git.run(*args).lines.reject(&.empty?)
    end

    private def self.zsh_init_script : String
      <<-'ZSH'
      wt() {
        local output
        output=$(command wt "$@") || return

        if [[ "$output" == cd\ * ]]; then
          export WT_PREV="$PWD"
          eval "$output"
        elif [[ -n "$output" ]]; then
          print -r -- "$output"
        fi
      }

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
          cd)
            local -a worktrees
            worktrees=(${(f)"$(command wt __complete cd_targets)"})
            _describe 'worktree' worktrees
            ;;
          rm)
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

      compdef _wt wt
      ZSH
    end
  end
end
