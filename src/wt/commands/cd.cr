module Wt
  module Commands
    class Cd
      def initialize(@resolver : Resolver)
      end

      def run(query : String? = nil) : Result
        return cd_previous if query == "-"
        return cd_main if main_query?(query)

        cd_worktree(query)
      end

      private def cd_main : Result
        Result.cd(@resolver.main_entry.path)
      end

      private def cd_previous : Result
        previous = ENV["WT_PREV"]?.presence

        unless previous
          Log.puts "no previous worktree"
          return Result.none
        end

        unless Dir.exists?(previous)
          Log.puts "previous worktree is gone: #{previous}"
          return Result.none
        end

        Result.cd(previous)
      end

      private def cd_worktree(query : String?) : Result
        entry = @resolver.pick(query, "only one worktree here, use 'wt new <branch>' to create another")
        return Result.none unless entry

        Result.cd(entry.path)
      end

      private def main_query?(query : String?) : Bool
        return false unless query
        return true if query == "main"

        query == @resolver.main_entry.branch
      end
    end
  end
end
