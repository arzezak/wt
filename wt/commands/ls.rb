module Wt
  module Commands
    class Ls
      def initialize(git)
        @git = git
      end

      def run(long: false)
        entries = @git.worktree_list
        return Result.print("no worktrees") if entries.empty?

        rows = [header(long)] + entries.map { |entry| row_for(entry, long) }
        Result.print(render_table(rows))
      end

      private

      def header(long)
        long ? ["BRANCH", "HEAD", "PATH"] : ["BRANCH", "PATH"]
      end

      def row_for(entry, long)
        columns = [branch_label(entry)]
        columns << entry.short_head if long
        columns << tilde(entry.path)
        columns
      end

      def render_table(rows)
        widths = column_widths(rows)
        lines = rows.map do |row|
          cells = []
          row.each_with_index do |cell, i|
            cells << (i < widths.size ? cell.ljust(widths[i]) : cell)
          end
          cells.join("  ")
        end
        lines.join("\n")
      end

      # The last column has no width because it is left unpadded.
      def column_widths(rows)
        (0...rows.first.size - 1).map { |i| rows.map { |row| row[i].size }.max }
      end

      def tilde(path)
        home = Dir.home
        path.start_with?(home) ? "~#{path[home.size..-1]}" : path
      end

      def branch_label(entry)
        label = entry.branch || "(detached)"
        entry.main? ? "#{label} *" : label
      end
    end
  end
end
