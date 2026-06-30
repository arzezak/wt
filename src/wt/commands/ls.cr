module Wt
  module Commands
    class Ls
      HEADER = {"BRANCH", "HEAD", "PATH"}

      def initialize(@git : Git, @repo : Repo)
      end

      def run : Result
        entries = @git.worktree_list
        return Result.print("no worktrees") if entries.empty?

        rows = [HEADER] + entries.map { |entry| row_for(entry) }
        Result.print(render_table(rows))
      end

      private def row_for(entry : Git::WorktreeEntry) : Tuple(String, String, String)
        {branch_label(entry), entry.short_head, entry.path}
      end

      private def branch_label(entry : Git::WorktreeEntry) : String
        label = entry.branch || "(detached)"
        @repo.main?(entry) ? "#{label} *" : label
      end

      private def render_table(rows : Array(Tuple(String, String, String))) : String
        widths = column_widths(rows)
        rows.map { |row| render_row(row, widths) }.join("\n")
      end

      private def column_widths(rows : Array(Tuple(String, String, String))) : Tuple(Int32, Int32)
        branch = rows.max_of { |row| row[0].size }
        head = rows.max_of { |row| row[1].size }
        {branch, head}
      end

      private def render_row(row, widths) : String
        branch, head = widths
        "#{row[0].ljust(branch)}  #{row[1].ljust(head)}  #{row[2]}"
      end
    end
  end
end
