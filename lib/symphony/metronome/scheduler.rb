#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'symphony'
require 'symphony/metronome'


### Manage the delta queue of events and associated actions.
###
class Symphony::Metronome::Scheduler
	extend Loggability, Configurability
	include Symphony::SignalHandling

	log_to :symphony
	config_key :metronome

	# Signals the daemon responds to.
	SIGNALS = [ :HUP, :INT, :TERM ]


	### Configurability API.
	###
	configurability do

		# Should Metronome register and schedule events via AMQP?
		# If +false+, you'll need a separate way to add event actions
		# to the database, and manually HUP the daemon.
		setting :listen, default: false
	end


	### Create and start an instanced daemon.
	###
	def self::run( &block )
		return new( block )
	end


	### Actions to perform when creating a new daemon.
	###
	private_class_method :new
	def initialize( block ) #:nodoc:

		# Start the queue subscriber for schedule changes.
		#
		if self.class.listen
			Symphony::Metronome::ScheduledEvent.db.disconnect
			@child = fork do
				$0 = 'Metronome (listener)'
				Symphony::Metronome::ScheduleTask.run
			end
			Process.setpgid( @child, 0 )
		end

		# Signal handling for the master (this) process.
		#
		self.set_up_signal_handling
		self.set_signal_traps( *SIGNALS )

		@queue = Symphony::Metronome::ScheduledEvent.load
		@proc  = block

		# Enter the main loop.
		self.start

	rescue => err
		self.log.error "%p while running: %s" % [ err.class, err.message ]
		self.log.debug "  " + err.backtrace.join( "\n  " )
		Process.kill( 'TERM', @child ) if self.class.listen
	end


	# The sorted set of ScheduledEvent objects.
	attr_reader :queue


	#########
	protected
	#########

	### Main daemon sleep loop.
	###
	def start
		$0 = "Metronome%s" % [ self.class.listen ? ' (executor)' : '' ]
		@running = true

		loop do
			wait = nil

			if ev = self.queue.first
				wait = ev.runtime - Time.now
				wait = 0 if wait < 0
				self.log.info "Next event in %0.3f second(s) (id: %d)..." % [ wait, ev.id ]
			else
				self.log.warn "No events scheduled.  Waiting indefinitely..."
			end

			self.process_events unless self.wait_for_signals( wait )
			break unless @running
		end
	end


	### Dispatch incoming signals to appropriate handlers.
	###
	def handle_signal( sig )
		case sig
		when :TERM, :INT
			@running = false
			Process.kill( sig.to_s, @child ) if self.class.listen

		when :HUP
			@queue = Symphony::Metronome::ScheduledEvent.load
			self.queue.each{|ev| ev.fire(&@proc) if ev.event.recurring }

		else
			self.log.debug "Unhandled signal: %s" % [ sig ]
		end
	end


	### Process all events that have reached their runtime.
	###
	def process_events
		now = Time.now

		self.queue.each do |ev|
			next unless now >= ev.runtime

			self.queue.delete( ev )
			rv = ev.fire( &@proc )

			# Reschedule the event and place it back on the queue.
			#
			if ev.event.recurring
				ev.reset_runtime
				self.queue.add( ev ) unless rv.nil?

			# It was a single run event, torch it!
			#
			else
				ev.delete

			end
		end
	end

end # Symphony::Metronome::Scheduler

