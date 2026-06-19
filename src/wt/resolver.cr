module Wt
  module Resolver
    def self.resolve(name : String, entries : Array(Git::WorktreeEntry)) : Git::WorktreeEntry
      exact = entries.find { |entry| entry.name == name }
      return exact if exact

      prefix_matches = entries.select { |entry| entry.name.starts_with?(name) }
      return prefix_matches.first if prefix_matches.size == 1

      candidates = entries.map(&.name).join(", ")
      if prefix_matches.size > 1
        raise "ambiguous name '#{name}', matches: #{prefix_matches.map(&.name).join(", ")}"
      end

      raise "no worktree matching '#{name}' (available: #{candidates})"
    end

    def self.non_main_entries : Array(Git::WorktreeEntry)
      main_path = Repo.main_repo_path
      Git.worktree_list.reject { |entry| entry.path == main_path }
    end

    def self.worktree_names : Array(String)
      non_main_entries.map(&.name)
    end
  end
end
