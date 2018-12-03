#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'pathname'
require 'symphony' unless defined?( Symphony )

module Symphony::Metronome
	extend Loggability,
	       Configurability

	# Library version constant
	VERSION = '0.2.3'

	# Version-control revision constant
	REVISION = %q$Revision: e3d11b2c9e48 $

	# The name of the environment variable to check for config file overrides
	CONFIG_ENV = 'METRONOME_CONFIG'

	# The path to the default config file
	DEFAULT_CONFIG_FILE = 'etc/config.yml'

	# The data directory that contains migration files.
	#
	DATADIR = if ENV['METRONOME_DATADIR']
				   Pathname( ENV['METRONOME_DATADIR'] )
			   elsif Gem.loaded_specs[ 'symphony-metronome' ] && File.exist?( Gem.loaded_specs['symphony-metronome'].datadir )
				   Pathname( Gem.loaded_specs['symphony-metronome'].datadir )
			   else
				   Pathname( __FILE__ ).dirname.parent.parent + 'data/symphony-metronome'
			   end


	# Loggability API -- use symphony's logger
	log_to :symphony

	# Configurability API
	config_key :metronome


	### Get the loaded config (a Configurability::Config object)
	def self::config
		Configurability.loaded_config
	end


	### Load the specified +config_file+, install the config in all objects with
	### Configurability, and call any callbacks registered via #after_configure.
	def self::load_config( config_file=nil, defaults=nil )
		config_file ||= ENV[ CONFIG_ENV ] || DEFAULT_CONFIG_FILE
		defaults    ||= Configurability.gather_defaults
		config = Configurability::Config.load( config_file, defaults )
		config.install
	end


	# The generic parse exception class.
	class TimeParseError < ArgumentError; end

	require 'symphony/metronome/scheduler'
	require 'symphony/metronome/intervalexpression'
	require 'symphony/metronome/scheduledevent'
	require 'symphony/tasks/scheduletask'


	###############
	module_function
	###############

	### Convenience method for running the scheduler.
	###
	def run( &block )
		raise LocalJumpError, "No block provided." unless block_given?
		return Symphony::Metronome::Scheduler.run( &block )
	end

end # Symphony::Metronome

