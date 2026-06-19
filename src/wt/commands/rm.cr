module Wt
  module Commands
    module Rm
      def self.run(query : String? = nil) : Result
        entries = Resolver.non_main_entries

        if entries.empty?
          STDERR.puts "wt: no worktrees to remove"
          return Result.none
        end

        unless query && !query.empty?
          names = entries.map(&.name).join(", ")
          STDERR.puts "wt: pass a name (tab-completes): #{names}"
          return Result.none
        end

        entry = Resolver.resolve(query, entries)

        inside = inside_worktree?(entry)
        if inside
          return Result.none unless confirm_removal?(entry)
        end

        Git.run(["worktree", "remove", entry.path])
        STDERR.puts "wt: removed #{entry.name} (branch preserved)"

        if inside
          Result.cd(Repo.main_repo_path)
        else
          Result.none
        end
      end

      private def self.inside_worktree?(entry : Git::WorktreeEntry) : Bool
        Dir.current.starts_with?(entry.path)
      end

      private def self.confirm_removal?(entry : Git::WorktreeEntry) : Bool
        STDERR.print "wt: you're inside #{entry.name}, remove and cd to main? [y/n] "
        answer = gets
        answer.try(&.strip.downcase) == "y"
      end
    end
  end
end
