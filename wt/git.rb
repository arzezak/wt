require "open3"

module Wt
  class Git
    class CommandError < StandardError
      attr_reader :stderr

      def initialize(stderr)
        @stderr = stderr
        message = stderr.strip
        super(message.empty? ? "git command failed" : message)
      end
    end

    WorktreeEntry = Data.define(:path, :head, :branch, :main) do
      def main?
        main
      end

      def short_head
        head[0, 7]
      end

      def name
        File.basename(path)
      end
    end

    def run(*args)
      stdout, stderr, status = Open3.capture3("git", *args)
      raise CommandError.new(stderr) unless status.success?

      stdout.strip
    end

    def worktree_list
      parse_worktree_list(run("worktree", "list", "--porcelain"))
    end

    def branch_exists?(branch)
      system("git", "show-ref", "--verify", "--quiet", "refs/heads/#{branch}") == true
    end

    def common_dir
      run("rev-parse", "--path-format=absolute", "--git-common-dir")
    end

    private

    def parse_worktree_list(output)
      entries = []
      output.split("\n\n").each do |stanza|
        # git lists the main worktree first.
        entry = parse_stanza(stanza, main: entries.empty?)
        entries << entry if entry
      end
      entries
    end

    def parse_stanza(stanza, main:)
      return nil if stanza.strip.empty?

      path = ""
      head = ""
      branch = nil

      stanza.each_line do |raw|
        line = raw.chomp
        if line.start_with?("worktree ")
          path = line.delete_prefix("worktree ")
        elsif line.start_with?("HEAD ")
          head = line.delete_prefix("HEAD ")
        elsif line.start_with?("branch ")
          branch = line.delete_prefix("branch refs/heads/")
        end
      end

      return nil if path.empty?

      WorktreeEntry.new(path: path, head: head, branch: branch, main: main)
    end
  end
end
