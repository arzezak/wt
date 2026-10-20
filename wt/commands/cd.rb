module Wt
  module Commands
    class Cd
      def initialize(resolver)
        @resolver = resolver
      end

      def run(query = nil)
        return cd_previous if query == "-"
        return cd_main if main_query?(query)

        cd_worktree(query)
      end

      private

      def cd_main
        Result.cd(@resolver.main_entry.path)
      end

      def cd_previous
        previous = ENV["WT_PREV"]

        if previous.nil? || previous.strip.empty?
          Log.puts "no previous worktree"
          return Result.none
        end

        unless Dir.exist?(previous)
          Log.puts "previous worktree is gone: #{previous}"
          return Result.none
        end

        Result.cd(previous)
      end

      def cd_worktree(query)
        entry = @resolver.pick(query, "only one worktree here, use 'wt new <branch>' to create another")
        return Result.none unless entry

        Result.cd(entry.path)
      end

      def main_query?(query)
        return false unless query
        return true if query == "main"

        query == @resolver.main_entry.branch
      end
    end
  end
end
