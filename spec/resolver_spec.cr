require "./spec_helper"

describe Wt::Resolver do
  entries = [
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/feature-auth", head: "aaa1111", branch: "feature/auth"),
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/feature-api", head: "bbb2222", branch: "feature/api"),
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/bugfix-login", head: "ccc3333", branch: "bugfix/login"),
  ]

  describe ".resolve" do
    it "resolves exact match" do
      match = Wt::Resolver.resolve("feature-auth", entries)
      match.entry.path.should eq("/repo/.worktrees/feature-auth")
    end

    it "resolves unique prefix" do
      match = Wt::Resolver.resolve("bugfix", entries)
      match.entry.path.should eq("/repo/.worktrees/bugfix-login")
    end

    it "raises on ambiguous prefix" do
      expect_raises(Exception, /ambiguous/) do
        Wt::Resolver.resolve("feature", entries)
      end
    end

    it "raises on no match" do
      expect_raises(Exception, /no worktree matching/) do
        Wt::Resolver.resolve("nonexistent", entries)
      end
    end
  end
end
