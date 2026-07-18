module Wt
  module Commands
    class Ls
      def initialize(@git : Git)
      end

      def run(long : Bool = false) : Result
        entries = @git.worktree_list
        return Result.print("no worktrees") if entries.empty?

        rows = [header(long)] + entries.map { |entry| row_for(entry, long) }
        Result.print(render_table(rows))
      end

      private def header(long : Bool) : Array(String)
        long ? ["BRANCH", "HEAD", "PATH"] : ["BRANCH", "PATH"]
      end

      private def row_for(entry : Git::WorktreeEntry, long : Bool) : Array(String)
        columns = [branch_label(entry)]
        columns << entry.short_head if long
        columns << tilde(entry.path)
        columns
      end

      private def render_table(rows : Array(Array(String))) : String
        widths = column_widths(rows)
        lines = rows.map do |row|
          row.map_with_index { |cell, i| (width = widths[i]?) ? cell.ljust(width) : cell }.join("  ")
        end
        lines.join("\n")
      end

      # The last column has no width because it is left unpadded.
      private def column_widths(rows : Array(Array(String))) : Array(Int32)
        (0...rows.first.size - 1).map { |i| rows.max_of { |row| row[i].size } }
      end

      private def tilde(path : String) : String
        home = Path.home.to_s
        path.starts_with?(home) ? "~#{path[home.size..]}" : path
      end

      private def branch_label(entry : Git::WorktreeEntry) : String
        label = entry.branch || "(detached)"
        entry.main? ? "#{label} *" : label
      end
    end
  end
end
