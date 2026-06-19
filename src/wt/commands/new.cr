module Wt
  module Commands
    module New
      def self.run(branch : String, base : String? = nil, hooks : Bool = true) : Result
        worktree_path = Repo.worktree_path_for(branch)

        if Dir.exists?(worktree_path)
          STDERR.puts "wt: worktree already exists at #{worktree_path}"
          return Result.cd(worktree_path)
        end

        ensure_worktree_root
        create_worktree(branch, worktree_path, base)
        run_hooks(worktree_path) if hooks
        Result.cd(worktree_path)
      end

      private def self.ensure_worktree_root : Nil
        root = Repo.worktree_root
        Dir.mkdir_p(root) unless Dir.exists?(root)
        Repo.ensure_ignored
      end

      private def self.create_worktree(branch : String, worktree_path : String, base : String?) : Nil
        if Git.branch_exists?(branch)
          Git.run(["worktree", "add", worktree_path, branch])
        else
          args = ["worktree", "add", "-b", branch, worktree_path]
          args << base if base
          Git.run(args)
        end
      end

      private def self.run_hooks(worktree_path : String) : Nil
        config = Config.load
        return if config.empty?

        copy_files(config, worktree_path)
        run_after_create(config, worktree_path)
      end

      private def self.copy_files(config : Config, worktree_path : String) : Nil
        main_path = Repo.main_repo_path
        config.copy.each do |relative_path|
          source = File.join(main_path, relative_path)
          destination = File.join(worktree_path, relative_path)
          unless File.exists?(source)
            STDERR.puts "wt: copy: skipping #{relative_path} (not found in main worktree)"
            next
          end
          destination_dir = File.dirname(destination)
          Dir.mkdir_p(destination_dir) unless Dir.exists?(destination_dir)
          File.copy(source, destination)
          STDERR.puts "wt: copy: #{relative_path}"
        end
      end

      private def self.run_after_create(config : Config, worktree_path : String) : Nil
        config.after_create.each do |command|
          STDERR.puts "wt: run: #{command}"
          status = Process.run(
            "sh", ["-c", command],
            chdir: worktree_path,
            output: Process::Redirect::Inherit,
            error: Process::Redirect::Inherit,
          )
          unless status.success?
            STDERR.puts "wt: after_create failed: #{command} (exit #{status.exit_code})"
            break
          end
        end
      end
    end
  end
end
