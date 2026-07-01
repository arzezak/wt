module Wt
  module Commands
    class Rm
      def initialize(@resolver : Resolver, @git : Git, @repo : Repo)
      end

      def run(query : String? = nil) : Result
        entry = @resolver.pick(query, "no worktrees to remove")
        return Result.none unless entry

        inside = inside_worktree?(entry)
        if inside
          return Result.none unless confirm_removal?(entry)
        end

        @git.run(["worktree", "remove", entry.path])
        Log.puts "removed #{entry.name} (branch preserved)"

        if inside
          Result.cd(@repo.main_repo_path)
        else
          Result.none
        end
      end

      private def inside_worktree?(entry : Git::WorktreeEntry) : Bool
        Dir.current.starts_with?(entry.path)
      end

      private def confirm_removal?(entry : Git::WorktreeEntry) : Bool
        Log.print "you're inside #{entry.name}, remove and cd to main? [y/n] "
        answer = gets
        answer.try(&.strip.downcase) == "y"
      end
    end
  end
end
