require_relative "test_helper"

class ResolverTest < Minitest::Test
  ENTRIES = [
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/feature-auth", head: "aaa1111", branch: "feature/auth", main: false),
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/feature-api", head: "bbb2222", branch: "feature/api", main: false),
    Wt::Git::WorktreeEntry.new(path: "/repo/.worktrees/bugfix-login", head: "ccc3333", branch: "bugfix/login", main: false),
  ].freeze

  def test_resolves_exact_match
    assert_equal "/repo/.worktrees/feature-auth", Wt::Resolver.resolve("feature-auth", ENTRIES).path
  end

  def test_resolves_unique_prefix
    assert_equal "/repo/.worktrees/bugfix-login", Wt::Resolver.resolve("bugfix", ENTRIES).path
  end

  def test_raises_on_ambiguous_prefix
    error = assert_raises(RuntimeError) { Wt::Resolver.resolve("feature", ENTRIES) }
    assert_match(/ambiguous/, error.message)
  end

  def test_raises_on_no_match
    error = assert_raises(RuntimeError) { Wt::Resolver.resolve("nonexistent", ENTRIES) }
    assert_match(/no worktree matching/, error.message)
  end
end
