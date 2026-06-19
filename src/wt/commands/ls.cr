module Wt
  module Commands
    module Ls
      def self.run : Result
        entries = Git.worktree_list
        return Result.print("no worktrees") if entries.empty?

        main_path = Repo.main_repo_path
        lines = entries.map { |entry| format_entry(entry, main_path) }
        Result.print(lines.join("\n"))
      end

      private def self.format_entry(entry : Git::WorktreeEntry, main_path : String) : String
        label = entry.branch || "(detached)"
        is_main = entry.path == main_path
        marker = is_main ? " *" : ""
        "#{label}#{marker}\t#{entry.short_head}\t#{entry.path}"
      end
    end
  end
end
