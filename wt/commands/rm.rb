module Wt
  module Commands
    class Rm
      def initialize(resolver, git)
        @resolver = resolver
        @git = git
      end

      def run(query = nil)
        entry = @resolver.pick(query, "no worktrees to remove")
        return Result.none unless entry

        inside = inside_worktree?(entry)
        return Result.none if inside && !confirm_removal?(entry)

        @git.run("worktree", "remove", entry.path)
        Log.puts "removed #{entry.name} (branch preserved)"

        inside ? Result.cd(@resolver.main_entry.path) : Result.none
      end

      private

      def inside_worktree?(entry)
        Dir.pwd.start_with?(entry.path)
      end

      def confirm_removal?(entry)
        Log.print "you're inside #{entry.name}, remove and cd to main? [y/n] "
        answer = $stdin.gets
        !answer.nil? && answer.strip.downcase == "y"
      end
    end
  end
end
