module Wt
  module Log
    def self.puts(message : String) : Nil
      STDERR.puts message
    end

    def self.print(message : String) : Nil
      STDERR.print message
    end

    # Announces a hook step (e.g. "copy", "run"), tree-prefixed so it's easy
    # to spot among the hooks' own output.
    def self.step(label : String, subject : String) : Nil
      STDERR.puts "🌳 #{label}: #{subject}"
    end
  end
end
