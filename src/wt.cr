require "./wt/log"
require "./wt/result"
require "./wt/git"
require "./wt/repo"
require "./wt/resolver"
require "./wt/config"
require "./wt/completion"
require "./wt/commands/*"
require "./wt/cli"

Wt::CLI.new.run(ARGV.to_a)
