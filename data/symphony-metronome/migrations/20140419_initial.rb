# vim: set nosta noet ts=4 sw=4:

### The initial Metronome DDL.
###
class Initial < Sequel::Migration

	def initialize( db )
		@db = db
	end

	def up
		create_table( :metronome ) do
			case @db.adapter_scheme
			when :postgres
				serial      :id,         primary_key: true
				timestamptz :created,    null: false
				text        :expression, null: false
				text        :options
			else
				Integer  :id,         auto_increment: true, primary_key: true
				DateTime :created,    null: false
				String   :expression, null: false
				String   :options
			end
		end
	end

	def down
		drop_table( :metronome )
	end
end

