require "./spec_helper"

describe Wt::Repo do
  around_each { |example| TestHelper.with_temp_repo(example) }

  describe "#main_repo_path" do
    it "returns the repo root" do
      repo = Wt::Repo.new(Wt::Git.new)
      repo.main_repo_path.should eq(Dir.current)
    end
  end

  describe "#worktree_root" do
    it "returns .worktrees under the repo root" do
      repo = Wt::Repo.new(Wt::Git.new)
      repo.worktree_root.should eq(File.join(Dir.current, ".worktrees"))
    end
  end

  describe "#worktree_path_for" do
    it "returns path under .worktrees" do
      repo = Wt::Repo.new(Wt::Git.new)
      expected = File.join(Dir.current, ".worktrees", "my-branch")
      repo.worktree_path_for("my-branch").should eq(expected)
    end

    it "sanitizes slashes to dashes" do
      repo = Wt::Repo.new(Wt::Git.new)
      expected = File.join(Dir.current, ".worktrees", "feature-foo")
      repo.worktree_path_for("feature/foo").should eq(expected)
    end
  end

  describe "#ensure_ignored" do
    it "adds .worktrees/ to .git/info/exclude" do
      repo = Wt::Repo.new(Wt::Git.new)
      repo.ensure_ignored

      exclude_path = File.join(Dir.current, ".git", "info", "exclude")
      File.read(exclude_path).should contain(".worktrees/")
    end

    it "is idempotent" do
      repo = Wt::Repo.new(Wt::Git.new)
      repo.ensure_ignored
      repo.ensure_ignored

      exclude_path = File.join(Dir.current, ".git", "info", "exclude")
      count = File.read(exclude_path).each_line.count { |line| line.strip == ".worktrees/" }
      count.should eq(1)
    end
  end
end
