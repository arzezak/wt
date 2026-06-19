require "./spec_helper"

describe Wt::Resolver do
  entries = [
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/feature-auth", head: "aaa1111", branch: "feature/auth"),
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/feature-api", head: "bbb2222", branch: "feature/api"),
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/bugfix-login", head: "ccc3333", branch: "bugfix/login"),
  ]

  around_each do |example|
    dir = TestHelper.create_temp_repo
    Dir.cd(dir) do
      example.run
    end
    TestHelper.cleanup(dir)
  end

  describe "#resolve" do
    it "resolves exact match" do
      git = Wt::Git.new
      repo = Wt::Repo.new(git)
      resolver = Wt::Resolver.new(repo, git)

      match = resolver.resolve("feature-auth", entries)
      match.path.should eq("/repo/.worktrees/feature-auth")
    end

    it "resolves unique prefix" do
      git = Wt::Git.new
      repo = Wt::Repo.new(git)
      resolver = Wt::Resolver.new(repo, git)

      match = resolver.resolve("bugfix", entries)
      match.path.should eq("/repo/.worktrees/bugfix-login")
    end

    it "raises on ambiguous prefix" do
      git = Wt::Git.new
      repo = Wt::Repo.new(git)
      resolver = Wt::Resolver.new(repo, git)

      expect_raises(Exception, /ambiguous/) do
        resolver.resolve("feature", entries)
      end
    end

    it "raises on no match" do
      git = Wt::Git.new
      repo = Wt::Repo.new(git)
      resolver = Wt::Resolver.new(repo, git)

      expect_raises(Exception, /no worktree matching/) do
        resolver.resolve("nonexistent", entries)
      end
    end
  end
end
