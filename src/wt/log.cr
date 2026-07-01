module Wt
  module Log
    def self.puts(message : String) : Nil
      STDERR.puts message
    end

    def self.print(message : String) : Nil
      STDERR.print message
    end

    # Announces an after_create callback about to run, tree-prefixed so it's
    # easy to spot among that callback's own output.
    def self.running(command : String) : Nil
      STDERR.puts "🌳 run: #{command}"
    end

    # Announces a file copied from the main worktree, tree-prefixed to match `running`.
    def self.copying(relative_path : String) : Nil
      STDERR.puts "🌳 copy: #{relative_path}"
    end
  end
end
