require "./spec_helper"

describe Wt::Git do
  around_each { |example| TestHelper.with_temp_repo(example) }

  describe "#worktree_list" do
    it "returns the main worktree" do
      git = Wt::Git.new
      entries = git.worktree_list

      entries.size.should eq(1)
      entries.first.path.should eq(Dir.current)
      entries.first.branch.should_not be_nil
      entries.first.main?.should be_true
    end
  end

  describe "#branch_exists?" do
    it "returns true for existing branch" do
      git = Wt::Git.new
      git.branch_exists?("main").should be_true
    end

    it "returns false for missing branch" do
      git = Wt::Git.new
      git.branch_exists?("nonexistent").should be_false
    end
  end

  describe "#common_dir" do
    it "returns .git directory" do
      git = Wt::Git.new
      git.common_dir.should eq(File.join(Dir.current, ".git"))
    end
  end

  describe Wt::Git::WorktreeEntry do
    it "returns short head" do
      entry = Wt::Git::WorktreeEntry.new(
        path: "/tmp/repo",
        head: "abc1234567890",
        branch: "main"
      )
      entry.short_head.should eq("abc1234")
    end

    it "returns name from path" do
      entry = Wt::Git::WorktreeEntry.new(
        path: "/tmp/repo/.worktrees/feature-foo",
        head: "abc1234",
        branch: "feature/foo"
      )
      entry.name.should eq("feature-foo")
    end
  end
end
