#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'set'
require 'sequel'
require 'sqlite3'
require 'yajl'
require 'symphony/metronome'

Sequel.extension :migration


### A class the represents the relationship between an interval and
### an event.
###
class Symphony::Metronome::ScheduledEvent
	extend Loggability, Configurability
	include Comparable

	log_to :symphony
	config_key :metronome


	# Configure defaults.
	#
	CONFIG_DEFAULTS = {
		db: 'sqlite:///tmp/metronome.db',
		splay: 0
	}

	class << self
		# A Sequel-style DB connection URI.
		attr_reader :db

		# Adjust recurring intervals by a random window.
		attr_reader :splay
	end


	######################################################################
	# C L A S S  M E T H O D S
	######################################################################

	### Configurability API.
	###
	def self::configure( config=nil )
		config = self.defaults.merge( config || {} )
		@db    = Sequel.connect( config.delete(:db) )
		@splay = config.delete( :splay )

		# Ensure the database is current.
		#
		migrations_dir = Symphony::Metronome::DATADIR + 'migrations'
		unless Sequel::Migrator.is_current?( self.db, migrations_dir.to_s )
			Sequel::Migrator.apply( self.db, migrations_dir.to_s )
		end
	end


	### Return a set of all known events, sorted by date of execution.
	### Delete any rows that are invalid expressions.
	###
	def self::load
		now    = Time.now
		events = SortedSet.new

		# Force reset the DB handle.
		self.db.disconnect

		self.log.debug "Parsing/loading all actions."
		self.db[ :metronome ].each do |event|
			begin
				event = new( event )
				events << event
			rescue ArgumentError, Symphony::Metronome::TimeParseError => err
				self.log.error "%p while parsing \"%s\": %s" % [
					err.class,
					event[:expression],
					err.message
				]
				self.log.debug "  " + err.backtrace.join( "\n  " )
				self.db[ :metronome ].filter( :id => event[:id] ).delete
			end
		end

		return events
	end


	######################################################################
	# I N S T A N C E  M E T H O D S
	######################################################################

	### Create a new ScheduledEvent object.
	###
	def initialize( row )
		@event    = Symphony::Metronome::IntervalExpression.parse( row[:expression], row[:created] )
		@options  = row.delete( :options )
		@id       = row.delete( :id )
		self.reset_runtime

		unless self.class.splay.zero?
			splay = Range.new( - self.class.splay, self.class.splay )
			@runtime = self.runtime + rand( splay )
		end
	end

	# The parsed interval expression.
	attr_reader :event

	# The unique ID number of the scheduled event.
	attr_reader :id

	# The options hash attached to this event.
	attr_reader :options

	# The exact time that this event will run.
	attr_reader :runtime


	### Set the datetime that this event should fire next.
	###
	def reset_runtime
		now = Time.now

		# Start time is in the future, so it's sufficent to be considered the run time.
		#
		if self.event.starting >= now
			@runtime = self.event.starting
			return
		end

		# Otherwise, the event should already be running (start time has already
		# elapsed), so schedule it forward on it's next interval iteration.
		#
		@runtime = now + self.event.interval
	end


	### Perform the action attached to the event.  Yields the
	### deserialized options, the action ID to the supplied block if
	### this event is okay to execute.
	###
	### Automatically remove the event if it has expired.
	###
	def fire
		rv = self.event.fire?

		if rv
			opts = Yajl.load( self.options )
			yield opts, self.id
		end

		self.delete if rv.nil?
		return rv
	end


	### Permanently remove this event from the database.
	###
	def delete
		self.log.debug "Removing action %p" % [ self.id ]
		self.class.db[ :metronome ].filter( :id => self.id ).delete
	end


	### Comparable interface, order by next run time, soonest first.
	###
	def <=>( other )
		return self.runtime <=> other.runtime
	end

end # Symphony::Metronome::ScheduledEvent

