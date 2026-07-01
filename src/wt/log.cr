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
  end
end
