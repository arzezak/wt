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
      process = Process.new(
        "git",
        args,
        output: Process::Redirect::Pipe,
        error: Process::Redirect::Pipe,
        chdir: chdir
      )
      output = process.output.gets_to_end
      error = process.error.gets_to_end
      status = process.wait
      raise CommandError.new(error) unless status.success?
      output.strip
    end

    def worktree_list(chdir : String? = nil) : Array(WorktreeEntry)
      output = run(["worktree", "list", "--porcelain"], chdir: chdir)
      parse_worktree_list(output)
    end

    def branch_exists?(branch : String, chdir : String? = nil) : Bool
      process = Process.new(
        "git",
        ["show-ref", "--verify", "--quiet", "refs/heads/#{branch}"],
        output: Process::Redirect::Close,
        error: Process::Redirect::Close,
        chdir: chdir
      )
      process.wait.success?
    end

    def common_dir(chdir : String? = nil) : String
      run(["rev-parse", "--path-format=absolute", "--git-common-dir"], chdir: chdir)
    end

    private def parse_worktree_list(output : String) : Array(WorktreeEntry)
      output.split("\n\n").compact_map { |stanza| parse_stanza(stanza) }
    end

    private def parse_stanza(stanza : String) : WorktreeEntry?
      return nil if stanza.strip.empty?

      path = ""
      head = ""
      branch = nil

      stanza.each_line do |line|
        if line.starts_with?("worktree ")
          path = line.sub("worktree ", "")
        elsif line.starts_with?("HEAD ")
          head = line.sub("HEAD ", "")
        elsif line.starts_with?("branch ")
          branch = line.sub("branch refs/heads/", "")
        end
      end

      return nil if path.empty?
      WorktreeEntry.new(path: path, head: head, branch: branch)
    end

    struct WorktreeEntry
      getter path : String
      getter head : String
      getter branch : String?

      def initialize(@path, @head, @branch)
      end

      def short_head : String
        @head[0, 7]
      end

      def name : String
        File.basename(@path)
      end
    end
  end
end
