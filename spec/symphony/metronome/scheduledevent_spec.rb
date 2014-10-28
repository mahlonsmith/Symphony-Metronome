#!/usr/bin/env rspec -wfd
# vim: set nosta noet ts=4 sw=4:

require_relative '../../helpers'

describe Symphony::Metronome::ScheduledEvent do

	let( :ds ) { described_class.db[:metronome] }

	before( :all ) do
		described_class.configure( :db => 'sqlite:///tmp/metronome-testing.db' )
	end

	after( :all ) do
		Pathname( '/tmp/metronome-testing.db' ).unlink
	end

	after( :each ) do
		described_class.db[ :metronome ].delete
	end


	context 'class methods' do

		after( :all ) do
			Timecop.return
		end

		# 2010-01-01 12:00
		let( :time ) { Time.at(1262376000) }

		before( :each ) do
			Timecop.travel( time )
		end

		it 'applies migrations upon initial config' do
			migrations = described_class.db[ :schema_migrations ].all
			expect( migrations.first[:filename] ).to eq( '20140419_initial.rb' )
		end

		it 'can load all stored events sorted by next execution time' do
			ds.insert(
				:created    => Time.now,
				:expression => 'at 2pm'
			)

			ds.insert(
				:created    => Time.now,
				:expression => 'at 3pm'
			)

			ds.insert(
				:created    => Time.now,
				:expression => 'at 1pm'
			)

			events = described_class.load.to_a

			expect( events.length ).to be( 3 )
			expect( events.first.event.instance_variable_get(:@exp) ).to eq( 'at 1pm' )
			expect( events.last.event.instance_variable_get(:@exp) ).to eq( 'at 3pm' )
		end

		it 'removes invalid expressions from storage when loading' do
			ds.insert(
				:created    => Time.now,
				:expression => 'blippity'
			)

			ds.insert(
				:created    => Time.now,
				:expression => 'at 3pm'
			)

			events = described_class.load.to_a
			expect( events.length ).to be( 1 )
		end
	end

	context 'an instance' do

		let( :time ) { Time.at(1262376000) }

		it 'can reschedule itself into the future when recurring (future start)' do
			ev = described_class.new(
				:created    => time,
				:expression => 'every 30 seconds'
			)

			Timecop.travel( time - 3600 ) do
				ev.reset_runtime
			end

			expect( ev.runtime ).to eq( time )
		end

		it 'can reschedule itself into the future when recurring (past start)' do
			ev = described_class.new(
				:created    => time,
				:expression => 'every 30 seconds'
			)

			Timecop.travel( time + 3600 ) do
				ev.reset_runtime
			end

			expect( ev.runtime ).to be >= time + 3600 + 30
		end

		it 'can reschedule itself into the future when recurring (recently run)' do
			ds.insert(
				:created    => time,
				:expression => 'every 30 seconds',
				:options    => "",
				:lastrun    => time - 12
			)
			ev = described_class.new( ds.first )

			Timecop.travel( time ) do
				ev.reset_runtime
			end

			expect( ev.runtime ).to be >= time + 18
		end

		it 'removes itself when firing if expired' do
			ds.insert(
				:created    => time,
				:expression => 'every 30 seconds for an hour',
				:options    => ""
			)
			ev = described_class.new( ds.first )

			expect( ev.fire {} ).to be_nil
			expect( ds.count ).to eq( 0 )
		end

		it 'yields a deserialized options hash if okay to fire' do
			ev = described_class.new(
				:created    => time,
				:expression => 'every 30 seconds',
				:options    => '{"excitement_level":12}'
			)

			res = 0
			ev.fire do |opts, id|
				res = opts['excitement_level']
			end

			expect( res ).to be( 12 )
		end

		it "won't re-fire recurring events if they already fired within their interval window" do
			ds.insert(
				:created    => time,
				:expression => 'every 30 seconds',
				:options    => '{"excitement_level":12}',
				:lastrun    => time - 12
			)
			ev = described_class.new( ds.first )

			res = 0
			Timecop.travel( time ) do
				rv = ev.fire do |opts, id|
					res = opts['excitement_level']
				end
				expect( rv ).to be_falsey
			end

			expect( res ).to be( 0 )
		end

		it 'randomizes start times if a splay is configured' do
			described_class.instance_variable_set( :@splay, 5 )

			Timecop.travel( time ) do
				100.times do
					ev = described_class.new(
						:created    => time,
						:expression => 'every 30 seconds'
					)

					diff = (( time + 30 ) - ev.runtime ).round
					expect( diff ).to be_within( 5 ).of( 0 )
				end
			end
		end
	end
end

