#!/usr/bin/env rake
# vim: set nosta noet ts=4 sw=4:

require 'rake/clean'
require 'pathname'

PROJECT = 'metronome'
BASEDIR = Pathname( __FILE__ ).dirname.relative_path_from( Pathname.pwd )
LIBDIR  = BASEDIR + 'lib' + 'symphony'
CLOBBER.include( 'coverage' )

$LOAD_PATH.unshift( LIBDIR.to_s )

EXPRESSION_RL = LIBDIR + 'metronome' + 'intervalexpression.rl'
EXPRESSION_RB = LIBDIR + 'metronome' + 'intervalexpression.rb'


if Rake.application.options.trace
    $trace = true
    $stderr.puts '$trace is enabled'
end

# get the current library version
$version = ( LIBDIR + "#{PROJECT}.rb" ).read.split(/\n/).
	select{|line| line =~ /VERSION =/}.first.match(/([\d|.]+)/)[1]

task :default => [ :spec, :docs, :package ]

# Generate the expression parser with Ragel
file EXPRESSION_RL
file EXPRESSION_RB
task EXPRESSION_RB => EXPRESSION_RL do |task|
	 sh 'ragel', '-R', '-T1', '-Ls', task.prerequisites.first
end
task :spec => EXPRESSION_RB


########################################################################
### P A C K A G I N G
########################################################################

require 'rubygems'
require 'rubygems/package_task'
spec = Gem::Specification.new do |s|
	s.email        = 'mahlon@martini.nu'
	s.homepage     = 'http://projects.martini.nu/ruby-modules'
	s.authors      = [ 'Mahlon E. Smith <mahlon@martini.nu>' ]
	s.platform     = Gem::Platform::RUBY
	s.summary      = "A natural language scheduling and task runner."
	s.name         = 'symphony-' + PROJECT
	s.version      = $version
	s.license      = 'BSD'
	s.has_rdoc     = true
	s.require_path = 'lib'
	s.bindir       = 'bin'
	s.files        = File.read( __FILE__ ).split( /^__END__/, 2 ).last.split
	s.executables  = %w[ metronome-exp ]
	s.description  = <<-EOF
		Metronome is a scheduler and task runner.  It can be used locally as a
		cron replacement, or as a network-wide job executor.  Events are stored
		via simple database rows, and optionally managed via AMQP events.
		Interval/time values are expressed with reasonably intuitive English
		phrases, ie.: 'at 2pm', or 'Starting in 20 minutes, run every 10 seconds
		and then finish in 2 days'.
	EOF
	s.required_rubygems_version = '>= 2.0.3'
	s.required_ruby_version = '>= 2.0.0'

	s.add_dependency 'symphony', '~> 0.11'
	s.add_dependency 'sequel',   '~> 5'
	s.add_dependency 'sqlite3',  '~> 1.3'

	s.add_development_dependency 'rspec', '~> 3.3'
	s.add_development_dependency 'simplecov', '~> 0.9'
	s.add_development_dependency 'timecop', '~> 0.7'
end

Gem::PackageTask.new( spec ) do |pkg|
	pkg.need_zip = true
	pkg.need_tar = true
end

########################################################################
### D O C U M E N T A T I O N
########################################################################

begin
	require 'rdoc/task'

	desc 'Generate rdoc documentation'
	RDoc::Task.new do |rdoc|
		rdoc.name       = :docs
		rdoc.rdoc_dir   = 'docs'
		rdoc.main       = "README.rdoc"
		rdoc.rdoc_files = [ 'lib', *FileList['*.rdoc'] ]
	end

	RDoc::Task.new do |rdoc|
		rdoc.name       = :doc_coverage
		rdoc.options    = [ '-C1' ]
	end

rescue LoadError
	$stderr.puts "Omitting 'docs' tasks, rdoc doesn't seem to be installed."
end


########################################################################
### T E S T I N G
########################################################################

begin
	require 'rspec/core/rake_task'
	task :test => :spec

	desc "Run specs"
	RSpec::Core::RakeTask.new do |t|
		t.pattern = "spec/**/*_spec.rb"
	end

	desc "Build a coverage report"
	task :coverage do
		ENV[ 'COVERAGE' ] = "yep"
		Rake::Task[ :spec ].invoke
	end

rescue LoadError
	$stderr.puts "Omitting testing tasks, rspec doesn't seem to be installed."
end


########################################################################
### M A N I F E S T
########################################################################
__END__
bin/metronome-exp
data/symphony-metronome/migrations/20140419_initial.rb
data/symphony-metronome/migrations/20141028_lastrun.rb
lib/symphony/metronome/intervalexpression.rb
lib/symphony/metronome/intervalexpression.rl
lib/symphony/metronome/mixins.rb
lib/symphony/metronome/scheduledevent.rb
lib/symphony/metronome/scheduler.rb
lib/symphony/metronome.rb
lib/symphony/tasks/scheduletask.rb
README.rdoc

