module Wt
  class Resolver
    def initialize(@repo : Repo, @git : Git)
    end

    def resolve(name : String, entries : Array(Git::WorktreeEntry)) : Git::WorktreeEntry
      exact = entries.find { |entry| entry.name == name }
      return exact if exact

      prefix_matches = entries.select { |entry| entry.name.starts_with?(name) }
      return prefix_matches.first if prefix_matches.size == 1

      if prefix_matches.size > 1
        raise "ambiguous name '#{name}', matches: #{prefix_matches.map(&.name).join(", ")}"
      end

      raise "no worktree matching '#{name}' (available: #{entries.map(&.name).join(", ")})"
    end

    def non_main_entries : Array(Git::WorktreeEntry)
      @git.worktree_list.reject { |entry| entry.path == @repo.main_repo_path }
    end

    def main_entry : Git::WorktreeEntry?
      @git.worktree_list.find { |entry| entry.path == @repo.main_repo_path }
    end

    def worktree_names : Array(String)
      non_main_entries.map(&.name)
    end
  end
end
