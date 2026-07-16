module Wt
  module Commands
    class Ls
      HEADER = {"BRANCH", "PATH"}

      def initialize(@git : Git, @repo : Repo)
      end

      def run : Result
        entries = @git.worktree_list
        return Result.print("no worktrees") if entries.empty?

        rows = [HEADER] + entries.map { |e| {branch_label(e), tilde(e.path)} }
        widths = rows.max_of { |r| r[0].size }
        lines = rows.map { |r| "#{r[0].ljust(widths)}  #{r[1]}" }
        Result.print(lines.join("\n"))
      end

      private def tilde(path : String) : String
        home = Path.home.to_s
        path.starts_with?(home) ? "~#{path[home.size..]}" : path
      end

      private def branch_label(entry : Git::WorktreeEntry) : String
        label = entry.branch || "(detached)"
        @repo.main?(entry) ? "#{label} *" : label
      end
    end
  end
end
