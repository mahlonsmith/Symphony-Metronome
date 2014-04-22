#!/usr/bin/env rspec -wfd
# vim: set nosta noet ts=4 sw=4:

require_relative '../../helpers'

describe Symphony::Metronome::ScheduleTask do

	let( :time ) { Time.at(1262376000) }
	let( :db ) { double('sequel db handle') }
	let( :actions ) { double('sequel dataset') }

	before( :each ) do
		allow( Symphony::Metronome::ScheduledEvent ).to receive( :db ).and_return( db )
		allow( db ).to receive( :[] ).with( :metronome ).and_return( actions )
		Timecop.freeze( time )
	end

	context 'creating a new event' do

		let( :task ) { described_class.new(nil) }
		let( :metadata ) {
			{
				:delivery_info => double( 'delivery info' ),
				:properties    => double( 'properties' )
			}
		}

		it 'fails with non-hash payloads' do
			expect( metadata[:delivery_info] ).to receive( :routing_key ).
				and_return( 'metronome.create' )

			expect {
				task.work( [], metadata )
			}.to raise_error( ArgumentError, 'Invalid payload.' )
		end

		it 'fails without an expression argument' do
			expect( metadata[:delivery_info] ).to receive( :routing_key ).
				and_return( 'metronome.create' )

			expect {
				task.work( {}, metadata )
			}.to raise_error( ArgumentError, 'Missing time expression.' )
		end

		it 'saves the event and seralized options to storage' do
			allow( Process ).to receive( :ppid ).and_return( 12000 )
			expect( metadata[:delivery_info] ).to receive( :routing_key ).
				and_return( 'metronome.create' )

			payload = {
				'expression'       => 'at 2pm',
				'excitement_level' => 12
			}

			expect( actions ).to receive( :insert ).with({
				:created     => time,
				:expression  => 'at 2pm',
				:options     => '{"excitement_level":12}'
			})
			expect( Process ).to receive( :kill ).with( 'HUP', 12000 )

			expect( task.work(payload, metadata) ).to be_truthy
		end

		it 'exits if it has become an orphaned process' do
			expect( metadata[:delivery_info] ).to receive( :routing_key ).
				and_return( 'metronome.create' )

			payload = {
				'expression'       => 'at 2pm',
				'excitement_level' => 12
			}

			expect( actions ).to receive( :insert ).with({
				:created     => time,
				:expression  => 'at 2pm',
				:options     => '{"excitement_level":12}'
			})
			expect( Process ).to_not receive( :kill )

			# parent gone! init takes over.
			allow( Process ).to receive( :ppid ).and_return( 1 )

			expect { task.work( payload, metadata ) }.to raise_error( SystemExit )
		end
	end

	context 'removing an existing event' do

		let( :task ) { described_class.new(nil) }
		let( :metadata ) {
			{
				:delivery_info => double( 'delivery info' ),
				:properties    => double( 'properties' )
			}
		}

		it 'removes rows matching the payload ID' do
			allow( Process ).to receive( :ppid ).and_return( 12000 )
			expect( metadata[:delivery_info] ).to receive( :routing_key ).
				and_return( 'metronome.delete' )

			payload = "44"
			row = double( 'filtered dataaset' )
			expect( row ).to receive( :delete )
			expect( actions ).to receive( :filter ).with( :id => 44 ).and_return( row )
			expect( Process ).to receive( :kill ).with( 'HUP', 12000 )

			task.work( payload, metadata )
		end

		it 'exits if it has become an orphaned process' do
			expect( metadata[:delivery_info] ).to receive( :routing_key ).
				and_return( 'metronome.delete' )

			payload = "44"
			row = double( 'filtered dataaset' )
			expect( row ).to receive( :delete )
			expect( actions ).to receive( :filter ).with( :id => 44 ).and_return( row )
			expect( Process ).to_not receive( :kill )

			# parent gone! init takes over.
			allow( Process ).to receive( :ppid ).and_return( 1 )

			expect { task.work( payload, metadata ) }.to raise_error( SystemExit )
		end
	end
end

