require "fileutils"

module Wt
  module Commands
    class New
      def initialize(git, repo)
        @git = git
        @repo = repo
      end

      def run(branch, base = nil, hooks: true)
        worktree_path = @repo.worktree_path_for(branch)

        if Dir.exist?(worktree_path)
          Log.puts "worktree already exists at #{worktree_path}"
          return Result.cd(worktree_path)
        end

        ensure_worktree_root
        create_worktree(branch, worktree_path, base)
        run_hooks(worktree_path) if hooks
        Result.cd(worktree_path)
      end

      private

      def ensure_worktree_root
        FileUtils.mkdir_p(@repo.worktree_root)
        @repo.ensure_ignored
      end

      def create_worktree(branch, worktree_path, base)
        if @git.branch_exists?(branch)
          @git.run("worktree", "add", worktree_path, branch)
        else
          args = ["worktree", "add", "-b", branch, worktree_path]
          args << base if base
          @git.run(*args)
        end
      end

      def run_hooks(worktree_path)
        config = Config.load(@repo.main_repo_path)
        copy_files(config, worktree_path)
        run_after_create(config, worktree_path)
      end

      def copy_files(config, worktree_path)
        main_path = @repo.main_repo_path
        config.copy.each do |relative_path|
          source = File.expand_path(relative_path, main_path)
          destination = File.expand_path(relative_path, worktree_path)
          unless source.start_with?(main_path + "/")
            Log.puts "copy: skipping #{relative_path} (path escapes repo)"
            next
          end
          unless File.exist?(source)
            Log.puts "copy: skipping #{relative_path} (not found in main worktree)"
            next
          end
          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.cp(source, destination)
          Log.step("copy", relative_path)
        end
      end

      def run_after_create(config, worktree_path)
        env = hook_env(worktree_path)

        config.after_create.each do |command|
          Log.step("run", command)
          pid = Process.spawn(env, "sh", "-c", command, chdir: worktree_path, out: $stderr, err: $stderr)
          Process.wait(pid)
          status = $?
          unless status.success?
            Log.puts "after_create failed: #{command} (exit #{status.exitstatus})"
            break
          end
        end
      end

      def hook_env(worktree_path)
        { "WT_WORKTREE_NAME" => File.basename(worktree_path) }
      end
    end
  end
end
