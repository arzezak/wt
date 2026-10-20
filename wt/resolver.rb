module Wt
  class Resolver
    def initialize(git)
      @git = git
      @worktrees = nil
    end

    def self.resolve(name, entries)
      exact = entries.find { |entry| entry.name == name }
      return exact if exact

      prefix_matches = entries.select { |entry| entry.name.start_with?(name) }
      return prefix_matches.first if prefix_matches.size == 1

      if prefix_matches.size > 1
        raise "ambiguous name '#{name}', matches: #{prefix_matches.map(&:name).join(", ")}"
      end

      raise "no worktree matching '#{name}' (available: #{entries.map(&:name).join(", ")})"
    end

    def pick(query, empty_message)
      entries = non_main_entries

      if entries.empty?
        Log.puts empty_message
        return nil
      end

      if query.nil? || query.strip.empty?
        Log.puts "pass a name (tab-completes): #{entries.map(&:name).join(", ")}"
        return nil
      end

      Resolver.resolve(query, entries)
    end

    def non_main_entries
      worktrees.reject(&:main?)
    end

    def main_entry
      worktrees.find(&:main?) || raise("cannot find the main worktree")
    end

    def worktree_names
      non_main_entries.map(&:name)
    end

    private

    def worktrees
      @worktrees ||= @git.worktree_list
    end
  end
end
