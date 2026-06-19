module Wt
  module Repo
    @@cached_main_repo_path : String? = nil

    def self.main_repo_path : String
      @@cached_main_repo_path ||= File.dirname(Git.common_dir)
    end

    def self.reset_cache : Nil
      @@cached_main_repo_path = nil
    end

    def self.worktree_root : String
      File.join(main_repo_path, ".worktrees")
    end

    def self.worktree_path_for(branch : String) : String
      sanitized = branch.gsub('/', '-')
      File.join(worktree_root, sanitized)
    end

    def self.ensure_ignored : Nil
      exclude_file = File.join(Git.common_dir, "info", "exclude")
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
