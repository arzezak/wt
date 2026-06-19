module Wt
  module Commands
    class Rm
      def initialize(@resolver : Resolver, @git : Git, @repo : Repo)
      end

      def run(query : String? = nil) : Result
        entries = @resolver.non_main_entries

        if entries.empty?
          STDERR.puts "wt: no worktrees to remove"
          return Result.none
        end

        unless query && !query.empty?
          names = entries.map(&.name).join(", ")
          STDERR.puts "wt: pass a name (tab-completes): #{names}"
          return Result.none
        end

        entry = @resolver.resolve(query, entries)

        inside = inside_worktree?(entry)
        if inside
          return Result.none unless confirm_removal?(entry)
        end

        @git.run(["worktree", "remove", entry.path])
        STDERR.puts "wt: removed #{entry.name} (branch preserved)"

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
        STDERR.print "wt: you're inside #{entry.name}, remove and cd to main? [y/n] "
        answer = gets
        answer.try(&.strip.downcase) == "y"
      end
    end
  end
end
