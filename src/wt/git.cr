module Wt
  class Git
    class CommandError < Exception
      getter stderr : String

      def initialize(@stderr)
        super(@stderr.strip.empty? ? "git command failed" : @stderr.strip)
      end
    end

    def run(*args : String) : String
      run(args.to_a)
    end

    def run(args : Array(String), chdir : String? = nil) : String
      output = IO::Memory.new
      error = IO::Memory.new
      status = Process.run("git", args, output: output, error: error, chdir: chdir)
      raise CommandError.new(error.to_s) unless status.success?
      output.to_s.strip
    end

    def worktree_list(chdir : String? = nil) : Array(WorktreeEntry)
      output = run(["worktree", "list", "--porcelain"], chdir: chdir)
      parse_worktree_list(output)
    end

    def branch_exists?(branch : String, chdir : String? = nil) : Bool
      Process.run("git", ["show-ref", "--verify", "--quiet", "refs/heads/#{branch}"], chdir: chdir).success?
    end

    def common_dir(chdir : String? = nil) : String
      run(["rev-parse", "--path-format=absolute", "--git-common-dir"], chdir: chdir)
    end

    private def parse_worktree_list(output : String) : Array(WorktreeEntry)
      entries = output.split("\n\n").compact_map { |stanza| parse_stanza(stanza) }
      # git lists the main worktree first.
      entries.map_with_index { |entry, index| index.zero? ? entry.copy_with(main: true) : entry }
    end

    private def parse_stanza(stanza : String) : WorktreeEntry?
      return nil if stanza.strip.empty?

      path = ""
      head = ""
      branch = nil

      stanza.each_line do |line|
        if line.starts_with?("worktree ")
          path = line.lchop("worktree ")
        elsif line.starts_with?("HEAD ")
          head = line.lchop("HEAD ")
        elsif line.starts_with?("branch ")
          branch = line.lchop("branch refs/heads/")
        end
      end

      return nil if path.empty?
      WorktreeEntry.new(path: path, head: head, branch: branch)
    end

    record WorktreeEntry, path : String, head : String, branch : String?, main : Bool = false do
      def main? : Bool
        main
      end

      def short_head : String
        head[0, 7]
      end

      def name : String
        File.basename(path)
      end
    end
  end
end
