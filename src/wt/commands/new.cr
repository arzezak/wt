module Wt
  module Commands
    class New
      def initialize(@git : Git, @repo : Repo)
      end

      def run(branch : String, base : String? = nil, hooks : Bool = true) : Result
        worktree_path = @repo.worktree_path_for(branch)

        if Dir.exists?(worktree_path)
          Log.puts "worktree already exists at #{worktree_path}"
          return Result.cd(worktree_path)
        end

        ensure_worktree_root
        create_worktree(branch, worktree_path, base)
        run_hooks(worktree_path) if hooks
        Result.cd(worktree_path)
      end

      private def ensure_worktree_root : Nil
        Dir.mkdir_p(@repo.worktree_root)
        @repo.ensure_ignored
      end

      private def create_worktree(branch : String, worktree_path : String, base : String?) : Nil
        if @git.branch_exists?(branch)
          @git.run(["worktree", "add", worktree_path, branch])
        else
          args = ["worktree", "add", "-b", branch, worktree_path]
          args << base if base
          @git.run(args)
        end
      end

      private def run_hooks(worktree_path : String) : Nil
        config = Config.load(@repo.main_repo_path)
        return if config.empty?

        copy_files(config, worktree_path)
        run_after_create(config, worktree_path)
      end

      private def copy_files(config : Config, worktree_path : String) : Nil
        config.copy.each do |relative_path|
          source = File.expand_path(relative_path, @repo.main_repo_path)
          destination = File.expand_path(relative_path, worktree_path)
          unless source.starts_with?(@repo.main_repo_path + "/")
            Log.puts "copy: skipping #{relative_path} (path escapes repo)"
            next
          end
          unless File.exists?(source)
            Log.puts "copy: skipping #{relative_path} (not found in main worktree)"
            next
          end
          Dir.mkdir_p(File.dirname(destination))
          File.copy(source, destination)
          Log.puts "copy: #{relative_path}"
        end
      end

      private def run_after_create(config : Config, worktree_path : String) : Nil
        config.after_create.each do |command|
          Log.running(command)
          status = Process.run(
            "sh", ["-c", command],
            chdir: worktree_path,
            output: STDERR,
            error: STDERR,
          )
          unless status.success?
            Log.puts "after_create failed: #{command} (exit #{status.exit_code})"
            break
          end
        end
      end
    end
  end
end
