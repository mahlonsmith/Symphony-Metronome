#!/usr/bin/env rspec -wfd
# vim: set nosta noet ts=4 sw=4:

require_relative '../../helpers'

describe Symphony::Metronome::Scheduler do

	before( :all ) do
		described_class.configure
	end

	it 'spins up an AMQP listener by default' do

		# described_class.run {}
		# expect( described_class.listen ).to eq( :sd )

	end
end

