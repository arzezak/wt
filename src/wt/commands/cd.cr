module Wt
  module Commands
    class Cd
      def initialize(@resolver : Resolver)
      end

      def run(query : String? = nil) : Result
        entries = @resolver.non_main_entries

        if entries.empty?
          STDERR.puts "wt: only one worktree here, use 'wt new <branch>' to create another"
          return Result.none
        end

        unless query && !query.empty?
          names = entries.map(&.name).join(", ")
          STDERR.puts "wt: pass a name (tab-completes): #{names}"
          return Result.none
        end

        match = @resolver.resolve(query, entries)
        Result.cd(match.path)
      end
    end
  end
end
