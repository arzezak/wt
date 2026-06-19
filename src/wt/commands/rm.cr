module Wt
  module Commands
    module Rm
      def self.run(query : String? = nil) : Result
        entries = Resolver.non_main_entries

        if entries.empty?
          STDERR.puts "wt: no worktrees to remove"
          return Result.none
        end

        entry = select_entry(query, entries)
        return Result.none unless entry

        Git.run(["worktree", "remove", entry.path])
        STDERR.puts "wt: removed #{entry.name} (branch preserved)"
        Result.none
      end

      private def self.select_entry(query : String?, entries : Array(Git::WorktreeEntry)) : Git::WorktreeEntry?
        if query && !query.empty?
          Resolver.resolve(query, entries)
        elsif Picker.fzf_available?
          Picker.pick(entries)
        else
          names = entries.map(&.name).join(", ")
          STDERR.puts "wt: pass a name (tab-completes): #{names}"
          nil
        end
      end
    end
  end
end
