module Wt
  module Commands
    class Ls
      def initialize(@git : Git, @repo : Repo)
      end

      def run : Result
        entries = @git.worktree_list
        return Result.print("no worktrees") if entries.empty?

        lines = entries.map { |entry| format_entry(entry) }
        Result.print(lines.join("\n"))
      end

      private def format_entry(entry : Git::WorktreeEntry) : String
        label = entry.branch || "(detached)"
        is_main = entry.path == @repo.main_repo_path
        marker = is_main ? " *" : ""
        "#{label}#{marker}\t#{entry.short_head}\t#{entry.path}"
      end
    end
  end
end
