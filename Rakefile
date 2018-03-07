require 'bundler/setup'
require 'English'

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |task|
  # if you use mediawiki-vagrant, rubocop will by default use it's .rubocop.yml
  # the next line makes it explicit that you want .rubocop.yml from the directory
  # where `bundle exec rake` is executed
  task.options = ['-c', '.rubocop.yml']
end

task default: [:test]

desc 'Compile the daemon and run its tests'
task :daemon_test do
  Dir.chdir('daemon') do
    system('make test')
    raise 'Daemon compilation or test failed' if $CHILD_STATUS.exitstatus != 0
  end
end

desc 'Run all build/tests commands (CI entry point)'
task test: [:rubocop, :daemon_test]
