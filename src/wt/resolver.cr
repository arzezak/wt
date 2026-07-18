module Wt
  class Resolver
    def initialize(@git : Git)
    end

    def self.resolve(name : String, entries : Array(Git::WorktreeEntry)) : Git::WorktreeEntry
      exact = entries.find { |entry| entry.name == name }
      return exact if exact

      prefix_matches = entries.select { |entry| entry.name.starts_with?(name) }
      return prefix_matches.first if prefix_matches.size == 1

      if prefix_matches.size > 1
        raise "ambiguous name '#{name}', matches: #{prefix_matches.map(&.name).join(", ")}"
      end

      raise "no worktree matching '#{name}' (available: #{entries.map(&.name).join(", ")})"
    end

    def pick(query : String?, empty_message : String) : Git::WorktreeEntry?
      entries = non_main_entries

      if entries.empty?
        Log.puts empty_message
        return nil
      end

      query = query.presence
      unless query
        Log.puts "pass a name (tab-completes): #{entries.map(&.name).join(", ")}"
        return nil
      end

      Resolver.resolve(query, entries)
    end

    def non_main_entries : Array(Git::WorktreeEntry)
      worktrees.reject(&.main?)
    end

    def main_entry : Git::WorktreeEntry
      worktrees.find(&.main?) || raise "cannot find the main worktree"
    end

    def worktree_names : Array(String)
      non_main_entries.map(&.name)
    end

    private def worktrees : Array(Git::WorktreeEntry)
      @worktrees ||= @git.worktree_list
    end
  end
end
