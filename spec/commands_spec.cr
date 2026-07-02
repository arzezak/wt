require "./spec_helper"

describe "wt commands (integration)" do
  around_each do |example|
    dir = TestHelper.create_temp_repo
    Dir.cd(dir) do
      example.run
    end
    TestHelper.cleanup(dir)
  end

  describe "ls" do
    it "lists the main worktree" do
      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "ls")

      exit_code.should eq(0)
      stdout.should contain("main")
    end

    it "prints a column header" do
      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "ls")

      exit_code.should eq(0)
      stdout.lines.first.should contain("BRANCH")
      stdout.lines.first.should contain("HEAD")
      stdout.lines.first.should contain("PATH")
    end

    it "aligns the HEAD column across rows" do
      TestHelper.run_wt(Dir.current, "new", "a-much-longer-branch-name")

      _, stdout, _ = TestHelper.run_wt(Dir.current, "ls")

      head_columns = stdout.lines.map { |line| line.index("HEAD") || line.index(/\b[0-9a-f]{7}\b/) }
      head_columns.uniq.size.should eq(1)
    end
  end

  describe "new" do
    it "creates a worktree and emits cd directive" do
      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "new", "test-feature")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stdout.should contain(".worktrees/test-feature")
      Dir.exists?(File.join(Dir.current, ".worktrees", "test-feature")).should be_true
    end

    it "sanitizes slashes in branch names" do
      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "new", "feature/slash")

      exit_code.should eq(0)
      stdout.should contain(".worktrees/feature-slash")
    end

    it "emits cd when worktree already exists" do
      TestHelper.run_wt(Dir.current, "new", "existing")

      exit_code, stdout, stderr = TestHelper.run_wt(Dir.current, "new", "existing")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stderr.should contain("already exists")
    end

    it "checks out existing branch into new worktree" do
      TestHelper.run_in(Dir.current, "git", "branch", "side-branch")

      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "new", "side-branch")

      exit_code.should eq(0)
      stdout.should contain(".worktrees/side-branch")
    end

    it "adds .worktrees/ to git exclude" do
      TestHelper.run_wt(Dir.current, "new", "ignored-test")

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

      TestHelper.run_wt(Dir.current, "new", "feature/foo")

      marker = File.join(Dir.current, ".worktrees", "feature-foo", "marker.txt")
      File.read(marker).should eq("name=feature-foo\n")
    end

    it "keeps hook output off stdout so the cd directive stays clean" do
      File.write(".wt.yml", <<-YAML)
      after_create:
        - echo "noise on stdout"
      YAML

      exit_code, stdout, stderr = TestHelper.run_wt(Dir.current, "new", "quiet-branch")

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

      _, _, stderr = TestHelper.run_wt(Dir.current, "new", "failing-branch")

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

      TestHelper.run_wt(Dir.current, "new", "copy-branch")

      copied = File.join(Dir.current, ".worktrees", "copy-branch", "shared.env")
      File.read(copied).should eq("SECRET=1")
    end

    it "skips a missing copy source with a warning on stderr" do
      File.write(".wt.yml", <<-YAML)
      copy:
        - does-not-exist.env
      YAML

      exit_code, _, stderr = TestHelper.run_wt(Dir.current, "new", "missing-copy-branch")

      exit_code.should eq(0)
      stderr.should contain("skipping does-not-exist.env")
    end

    it "skips --no-hooks entirely" do
      File.write(".wt.yml", <<-YAML)
      after_create:
        - touch should-not-exist.txt
      YAML

      TestHelper.run_wt(Dir.current, "new", "no-hooks-branch", "--no-hooks")

      marker = File.join(Dir.current, ".worktrees", "no-hooks-branch", "should-not-exist.txt")
      File.exists?(marker).should be_false
    end
  end

  describe "cd" do
    it "reports single worktree" do
      exit_code, stdout, stderr = TestHelper.run_wt(Dir.current, "cd", "anything")

      exit_code.should eq(0)
      stdout.should be_empty
      stderr.should contain("only one worktree")
    end

    it "resolves by exact name" do
      TestHelper.run_wt(Dir.current, "new", "target")

      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "cd", "target")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stdout.should contain(".worktrees/target")
    end

    it "resolves by unique prefix" do
      TestHelper.run_wt(Dir.current, "new", "unique-branch")

      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "cd", "uni")

      exit_code.should eq(0)
      stdout.should contain(".worktrees/unique-branch")
    end

    it "fails on no match" do
      TestHelper.run_wt(Dir.current, "new", "some-branch")

      exit_code, _, stderr = TestHelper.run_wt(Dir.current, "cd", "nonexistent")

      exit_code.should eq(1)
      stderr.should contain("no worktree matching")
    end

    it "returns to the main worktree with 'main'" do
      TestHelper.run_wt(Dir.current, "new", "leaf")

      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "cd", "main")

      exit_code.should eq(0)
      stdout.should start_with("cd ")
      stdout.should_not contain(".worktrees")
    end

    it "returns to the previous worktree with '-'" do
      previous = File.join(Dir.current, ".worktrees", "leaf")
      TestHelper.run_wt(Dir.current, "new", "leaf")

      ENV["WT_PREV"] = previous
      begin
        exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "cd", "-")

        exit_code.should eq(0)
        stdout.should contain("leaf")
      ensure
        ENV.delete("WT_PREV")
      end
    end

    it "errors on '-' when there is no previous worktree" do
      ENV.delete("WT_PREV")

      exit_code, stdout, stderr = TestHelper.run_wt(Dir.current, "cd", "-")

      exit_code.should eq(0)
      stdout.should be_empty
      stderr.should contain("no previous worktree")
    end
  end

  describe "rm" do
    it "removes a worktree by name" do
      TestHelper.run_wt(Dir.current, "new", "to-remove")
      wt_path = File.join(Dir.current, ".worktrees", "to-remove")
      Dir.exists?(wt_path).should be_true

      exit_code, _, stderr = TestHelper.run_wt(Dir.current, "rm", "to-remove")

      exit_code.should eq(0)
      stderr.should contain("removed to-remove")
      stderr.should contain("branch preserved")
      Dir.exists?(wt_path).should be_false
    end

    it "reports no worktrees to remove" do
      exit_code, _, stderr = TestHelper.run_wt(Dir.current, "rm", "anything")

      exit_code.should eq(0)
      stderr.should contain("no worktrees to remove")
    end
  end

  describe "help" do
    it "shows help text" do
      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "help")

      exit_code.should eq(0)
      stdout.should contain("git worktrees")
    end
  end

  describe "unknown subcommand" do
    it "fails with error" do
      exit_code, _, stderr = TestHelper.run_wt(Dir.current, "bogus")

      exit_code.should eq(1)
      stderr.should contain("unknown subcommand 'bogus'")
    end
  end

  describe "__complete" do
    it "returns worktree names" do
      TestHelper.run_wt(Dir.current, "new", "comp-test")

      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "__complete", "worktrees")

      exit_code.should eq(0)
      stdout.should contain("comp-test")
    end

    it "returns branch names" do
      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "__complete", "branches")

      exit_code.should eq(0)
      stdout.should contain("main")
    end

    it "returns subcommands" do
      exit_code, stdout, _ = TestHelper.run_wt(Dir.current, "__complete", "subcommands")

      exit_code.should eq(0)
      stdout.should contain("cd")
      stdout.should contain("new")
      stdout.should contain("rm")
    end
  end
end
