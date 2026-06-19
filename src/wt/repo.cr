module Wt
  module Repo
    def self.main_repo_path : String
      common_dir = Git.common_dir
      File.dirname(common_dir)
    end

    def self.worktree_root : String
      File.join(main_repo_path, ".worktrees")
    end

    def self.worktree_path_for(branch : String) : String
      sanitized = branch.gsub('/', '-')
      File.join(worktree_root, sanitized)
    end

    def self.ensure_ignored : Nil
      common_dir = Git.common_dir
      exclude_file = File.join(common_dir, "info", "exclude")
      marker = ".worktrees/"

      if File.exists?(exclude_file)
        return if File.read(exclude_file).each_line.any? { |line| line.strip == marker }
      end

      File.open(exclude_file, "a") do |file|
        file.puts marker
      end
    end
  end
end
