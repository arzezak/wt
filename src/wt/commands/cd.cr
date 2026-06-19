module Wt
  module Commands
    module Cd
      def self.run(query : String? = nil) : Result
        all_entries = Git.worktree_list
        if all_entries.size <= 1
          STDERR.puts "wt: only one worktree here, use 'wt new <branch>' to create another"
          return Result.none
        end

        entries = Resolver.non_main_entries

        if query && !query.empty?
          resolve_by_name(query, entries)
        else
          pick_interactively(entries)
        end
      end

      private def self.resolve_by_name(query : String, entries : Array(Git::WorktreeEntry)) : Result
        match = Resolver.resolve(query, entries)
        Result.cd(match.path)
      end

      private def self.pick_interactively(entries : Array(Git::WorktreeEntry)) : Result
        unless Picker.fzf_available?
          names = entries.map(&.name).join(", ")
          STDERR.puts "wt: pass a name (tab-completes): #{names}"
          return Result.none
        end

        selected = Picker.pick(entries)
        unless selected
          STDERR.puts "wt: no worktree selected"
          return Result.none
        end

        Result.cd(selected.path)
      end
    end
  end
end
