# vim: set nosta noet ts=4 sw=4:

### Add a 'lastrun' time stamp for recurring events.
###
class Lastrun < Sequel::Migration

	def initialize( db )
		@db = db
	end

	def up
		if @db.adapter_scheme == :postgres
			add_column :metronome, :lastrun, 'timestamptz'
		else
			add_column :metronome, :lastrun, DateTime
		end
	end

	def down
		drop_column :metronome, :lastrun
	end
end

