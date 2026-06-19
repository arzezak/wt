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
      stdout.should contain("git worktrees, fuzzily")
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
