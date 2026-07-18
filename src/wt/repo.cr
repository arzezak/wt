module Wt
  class Repo
    def initialize(@git : Git)
    end

    def main_repo_path : String
      File.dirname(common_dir)
    end

    def worktree_root : String
      File.join(main_repo_path, ".worktrees")
    end

    def worktree_path_for(branch : String) : String
      sanitized = branch.gsub('/', '-')
      File.join(worktree_root, sanitized)
    end

    def ensure_ignored : Nil
      marker = ".worktrees/"
      exclude_file = File.join(common_dir, "info", "exclude")

      if File.exists?(exclude_file)
        return if File.read(exclude_file).each_line.any? { |line| line.strip == marker }
      end

      File.open(exclude_file, "a") do |file|
        file.puts marker
      end
    end

    # Lazy so commands that never need the repo path skip the git spawn.
    private def common_dir : String
      @common_dir ||= @git.common_dir
    end
  end
end
