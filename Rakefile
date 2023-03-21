# vim: set noet sta sw=4 ts=4 :
# -*- ruby -*-

require 'rake/deveiate'
require 'pathname'

Rake::DevEiate.setup( 'symphony-metronome' ) do |project|
	project.publish_to = 'martini.nu:martini/www/docs/symphony-metronome'
	project.summary = <<~END_SUM
		A natural language scheduling and task runner for Symphony.
	END_SUM
	project.description = <<~END_DESC
		Metronome is a scheduler and task runner.  It can be used locally as a
		cron replacement, or as a network-wide job executor.  Events are stored
		via simple database rows, and optionally managed via AMQP events.
		Interval/time values are expressed with reasonably intuitive English
		phrases, ie.: 'at 2pm', or 'Starting in 20 minutes, run every 10 seconds
		and then finish in 2 days'.
		END_DESC
	project.authors = [ 'Mahlon E. Smith <mahlon@martini.nu>' ]
    project.rdoc_generator = :sixfish
end

CLOBBER.include( 'coverage' )

BASEDIR = Pathname( __FILE__ ).dirname.relative_path_from( Pathname.pwd )
LIBDIR  = BASEDIR + 'lib' + 'symphony'

EXPRESSION_RL = LIBDIR + 'metronome' + 'intervalexpression.rl'
EXPRESSION_RB = LIBDIR + 'metronome' + 'intervalexpression.rb'

CLOBBER.include( EXPRESSION_RB.to_s )

task :default => [ :spec, :docs, :package ]

# Generate the expression parser with Ragel
file EXPRESSION_RL
file EXPRESSION_RB
task EXPRESSION_RB => EXPRESSION_RL do |task|
	 sh 'ragel', '-R', '-T1', '-Ls', task.prerequisites.first
end

task :spec => EXPRESSION_RB
task :package => EXPRESSION_RB

