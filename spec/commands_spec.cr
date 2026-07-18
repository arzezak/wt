require "./spec_helper"

describe "wt commands (integration)" do
  around_each { |example| TestHelper.with_temp_repo(example) }

  describe "ls" do
    it "lists the main worktree" do
      exit_code, stdout, _ = TestHelper.run_wt("ls")

      exit_code.should eq(0)
      stdout.should contain("main")
    end

    it "prints a column header" do
      exit_code, stdout, _ = TestHelper.run_wt("ls")

      exit_code.should eq(0)
      stdout.lines.first.should contain("BRANCH")
      stdout.lines.first.should_not contain("HEAD")
      stdout.lines.first.should contain("PATH")
    end

    it "shortens home directory to tilde" do
      _, stdout, _ = TestHelper.run_wt("ls")

      path_column = stdout.lines.skip(1).map { |line| line.split(/\s{2,}/).last }
      path_column.each do |path|
        path.should_not start_with(Path.home.to_s)
      end
    end

    it "adds the HEAD column with -l" do
      exit_code, stdout, _ = TestHelper.run_wt("ls", "-l")

      exit_code.should eq(0)
      stdout.lines.first.should contain("BRANCH")
      stdout.lines.first.should contain("HEAD")
      stdout.lines.first.should contain("PATH")
    end

    it "aligns the HEAD column across rows with -l" do
      TestHelper.run_wt("new", "a-much-longer-branch-name")

      _, stdout, _ = TestHelper.run_wt("ls", "-l")

      head_columns = stdout.lines.map { |line| line.index(/\b(HEAD|[0-9a-f]{7})\b/) }
      head_columns.uniq.size.should eq(1)
    end

    it "rejects unknown flags" do
      exit_code, _, stderr = TestHelper.run_wt("ls", "-b")

      exit_code.should_not eq(0)
      stderr.should contain("unknown flag '-b'")
    end
  end

  describe "new" do
    it "creates a worktree and emits cd directive" do
      exit_code, stdout, _ = TestHelper.run_wt("new", "test-feature")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stdout.should contain(".worktrees/test-feature")
      Dir.exists?(File.join(Dir.current, ".worktrees", "test-feature")).should be_true
    end

    it "sanitizes slashes in branch names" do
      exit_code, stdout, _ = TestHelper.run_wt("new", "feature/slash")

      exit_code.should eq(0)
      stdout.should contain(".worktrees/feature-slash")
    end

    it "emits cd when worktree already exists" do
      TestHelper.run_wt("new", "existing")

      exit_code, stdout, stderr = TestHelper.run_wt("new", "existing")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stderr.should contain("already exists")
    end

    it "checks out existing branch into new worktree" do
      TestHelper.run_in("git", "branch", "side-branch")

      exit_code, stdout, _ = TestHelper.run_wt("new", "side-branch")

      exit_code.should eq(0)
      stdout.should contain(".worktrees/side-branch")
    end

    it "adds .worktrees/ to git exclude" do
      TestHelper.run_wt("new", "ignored-test")

      exclude_path = File.join(Dir.current, ".git", "info", "exclude")
      File.read(exclude_path).should contain(".worktrees/")
    end
  end

  describe "new (hooks)" do
    it "runs after_create with WT_WORKTREE_NAME set" do
      File.write(".wt.yml", <<-YAML)
      after_create:
        - echo "name=$WT_WORKTREE_NAME" > marker.txt
      YAML

      TestHelper.run_wt("new", "feature/foo")

      marker = File.join(Dir.current, ".worktrees", "feature-foo", "marker.txt")
      File.read(marker).should eq("name=feature-foo\n")
    end

    it "keeps hook output off stdout so the cd directive stays clean" do
      File.write(".wt.yml", <<-YAML)
      after_create:
        - echo "noise on stdout"
      YAML

      exit_code, stdout, stderr = TestHelper.run_wt("new", "quiet-branch")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stdout.should_not contain("noise")
      stderr.should contain("noise on stdout")
    end

    it "stops running after_create commands on first failure" do
      File.write(".wt.yml", <<-YAML)
      after_create:
        - "false"
        - touch should-not-exist.txt
      YAML

      _, _, stderr = TestHelper.run_wt("new", "failing-branch")

      marker = File.join(Dir.current, ".worktrees", "failing-branch", "should-not-exist.txt")
      File.exists?(marker).should be_false
      stderr.should contain("after_create failed")
    end

    it "copies files from the main worktree" do
      File.write("shared.env", "SECRET=1")
      File.write(".wt.yml", <<-YAML)
      copy:
        - shared.env
      YAML

      TestHelper.run_wt("new", "copy-branch")

      copied = File.join(Dir.current, ".worktrees", "copy-branch", "shared.env")
      File.read(copied).should eq("SECRET=1")
    end

    it "skips a missing copy source with a warning on stderr" do
      File.write(".wt.yml", <<-YAML)
      copy:
        - does-not-exist.env
      YAML

      exit_code, _, stderr = TestHelper.run_wt("new", "missing-copy-branch")

      exit_code.should eq(0)
      stderr.should contain("skipping does-not-exist.env")
    end

    it "skips --no-hooks entirely" do
      File.write(".wt.yml", <<-YAML)
      after_create:
        - touch should-not-exist.txt
      YAML

      TestHelper.run_wt("new", "no-hooks-branch", "--no-hooks")

      marker = File.join(Dir.current, ".worktrees", "no-hooks-branch", "should-not-exist.txt")
      File.exists?(marker).should be_false
    end
  end

  describe "cd" do
    it "reports single worktree" do
      exit_code, stdout, stderr = TestHelper.run_wt("cd", "anything")

      exit_code.should eq(0)
      stdout.should be_empty
      stderr.should contain("only one worktree")
    end

    it "resolves by exact name" do
      TestHelper.run_wt("new", "target")

      exit_code, stdout, _ = TestHelper.run_wt("cd", "target")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stdout.should contain(".worktrees/target")
    end

    it "resolves by unique prefix" do
      TestHelper.run_wt("new", "unique-branch")

      exit_code, stdout, _ = TestHelper.run_wt("cd", "uni")

      exit_code.should eq(0)
      stdout.should contain(".worktrees/unique-branch")
    end

    it "fails on no match" do
      TestHelper.run_wt("new", "some-branch")

      exit_code, _, stderr = TestHelper.run_wt("cd", "nonexistent")

      exit_code.should eq(1)
      stderr.should contain("no worktree matching")
    end

    it "returns to the main worktree with 'main'" do
      TestHelper.run_wt("new", "leaf")

      exit_code, stdout, _ = TestHelper.run_wt("cd", "main")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stdout.should_not contain(".worktrees")
    end

    it "returns to the previous worktree with '-'" do
      previous = File.join(Dir.current, ".worktrees", "leaf")
      TestHelper.run_wt("new", "leaf")

      ENV["WT_PREV"] = previous
      begin
        exit_code, stdout, _ = TestHelper.run_wt("cd", "-")

        exit_code.should eq(0)
        stdout.should contain("leaf")
      ensure
        ENV.delete("WT_PREV")
      end
    end

    it "errors on '-' when there is no previous worktree" do
      ENV.delete("WT_PREV")

      exit_code, stdout, stderr = TestHelper.run_wt("cd", "-")

      exit_code.should eq(0)
      stdout.should be_empty
      stderr.should contain("no previous worktree")
    end
  end

  describe "rm" do
    it "removes a worktree by name" do
      TestHelper.run_wt("new", "to-remove")
      wt_path = File.join(Dir.current, ".worktrees", "to-remove")
      Dir.exists?(wt_path).should be_true

      exit_code, _, stderr = TestHelper.run_wt("rm", "to-remove")

      exit_code.should eq(0)
      stderr.should contain("removed to-remove")
      stderr.should contain("branch preserved")
      Dir.exists?(wt_path).should be_false
    end

    it "reports no worktrees to remove" do
      exit_code, _, stderr = TestHelper.run_wt("rm", "anything")

      exit_code.should eq(0)
      stderr.should contain("no worktrees to remove")
    end
  end

  describe "help" do
    it "shows help text" do
      exit_code, stdout, _ = TestHelper.run_wt("help")

      exit_code.should eq(0)
      stdout.should contain("git worktrees")
    end
  end

  describe "unknown subcommand" do
    it "fails with error" do
      exit_code, _, stderr = TestHelper.run_wt("bogus")

      exit_code.should eq(1)
      stderr.should contain("unknown subcommand 'bogus'")
    end
  end

  describe "__complete" do
    it "returns worktree names" do
      TestHelper.run_wt("new", "comp-test")

      exit_code, stdout, _ = TestHelper.run_wt("__complete", "worktrees")

      exit_code.should eq(0)
      stdout.should contain("comp-test")
    end

    it "returns branch names" do
      exit_code, stdout, _ = TestHelper.run_wt("__complete", "branches")

      exit_code.should eq(0)
      stdout.should contain("main")
    end

    it "returns subcommands" do
      exit_code, stdout, _ = TestHelper.run_wt("__complete", "subcommands")

      exit_code.should eq(0)
      stdout.should contain("cd")
      stdout.should contain("new")
      stdout.should contain("rm")
    end
  end
end
