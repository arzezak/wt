module Wt
  module Commands
    class Cd
      PREVIOUS_TOKEN = "-"
      MAIN_TOKEN = "main"

      def initialize(@resolver : Resolver, @repo : Repo)
      end

      def run(query : String? = nil) : Result
        return cd_previous if query == PREVIOUS_TOKEN
        return cd_main if main_query?(query)

        cd_worktree(query)
      end

      private def cd_main : Result
        Result.cd(@repo.main_repo_path)
      end

      private def cd_previous : Result
        previous = ENV["WT_PREV"]?

        if previous.nil? || previous.empty?
          STDERR.puts "wt: no previous worktree"
          return Result.none
        end

        unless Dir.exists?(previous)
          STDERR.puts "wt: previous worktree is gone: #{previous}"
          return Result.none
        end

        Result.cd(previous)
      end

      private def cd_worktree(query : String?) : Result
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

      private def main_query?(query : String?) : Bool
        return false unless query
        return true if query == MAIN_TOKEN

        main = @resolver.main_entry
        !main.nil? && query == main.branch
      end
    end
  end
end
