#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'symphony'
require 'symphony/routing'
require 'symphony/metronome'


### Accept metronome scheduling events, translating them
### to DB rows for persistence.
###
class Symphony::Metronome::ScheduleTask < Symphony::Task
	include Symphony::Routing

	queue_name 'metronome'
	timeout 30

	### Get a handle to the database.
	###
	def initialize( * )
		@db = Symphony::Metronome::ScheduledEvent.db
		@actions = @db[ :metronome ]
		super
	end

	# The Sequel dataset of scheduled event actions.
	attr_reader :actions


	### Accept a new scheduled event.  The payload should be a free
	### form hash of options, along with an expression string that
	### conforms to IntervalExpression.
	###
	###   {
	###       :expression  => 'run 25 times for an hour',
	###       :payload     => { ... },
	###   }
	###
	on 'metronome.create' do |payload, metadata|
		raise ArgumentError, 'Invalid payload.' unless payload.is_a?( Hash )
		exp = payload.delete( 'expression' )
		raise ArgumentError, 'Missing time expression.' unless exp

		self.actions.insert(
			:created     => Time.now,
			:expression  => exp,
			:options     => Yajl.dump( payload )
		)

		self.signal_parent
		return true
	end


	### Delete an existing scheduled event.
	### The payload is the id of the action (row) to delete.
	###
	on 'metronome.delete' do |id, metadata|
		self.actions.filter( :id => id.to_i ).delete
		self.signal_parent
		return true
	end


	### Tell our parent (the Metronome broadcaster) to re-read its event
	### list.
	###
	def signal_parent
		parent = Process.ppid

		# Check to make sure we weren't orphaned.
		#
		if parent == 1
			self.log.error "Lost my parent process?  Exiting."
			exit 1
		end

		Process.kill( 'HUP', parent )
	end
end

