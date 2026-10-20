module Wt
  class Repo
    def initialize(git)
      @git = git
      @common_dir = nil
    end

    def main_repo_path
      File.dirname(common_dir)
    end

    def worktree_root
      File.join(main_repo_path, ".worktrees")
    end

    def worktree_path_for(branch)
      File.join(worktree_root, branch.tr("/", "-"))
    end

    def ensure_ignored
      marker = ".worktrees/"
      exclude_file = File.join(common_dir, "info", "exclude")

      if File.exist?(exclude_file)
        return if File.read(exclude_file).lines.any? { |line| line.strip == marker }
      end

      File.open(exclude_file, "a") do |file|
        file.puts marker
      end
    end

    private

    # Lazy so commands that never need the repo path skip the git spawn.
    def common_dir
      @common_dir ||= @git.common_dir
    end
  end
end
