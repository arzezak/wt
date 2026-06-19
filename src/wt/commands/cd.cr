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

        unless query && !query.empty?
          names = entries.map(&.name).join(", ")
          STDERR.puts "wt: pass a name (tab-completes): #{names}"
          return Result.none
        end

        match = Resolver.resolve(query, entries)
        Result.cd(match.path)
      end
    end
  end
end
