# vim: set nosta noet ts=4 sw=4 ft=rspec:

require_relative '../../helpers'


describe Symphony::Metronome::IntervalExpression do

	# 2010-01-01 12:00
	let( :past ) { Time.at(1262376000) }

	before( :each ) do
		Timecop.freeze( past )
	end

	it "can't be instantiated directly" do
		expect { described_class.new }.to raise_error( NoMethodError )
	end

	it "raises an exception if unable to parse the expression" do
		expect {
			described_class.parse( 'wut!' )
		}.to raise_error( Symphony::Metronome::TimeParseError, /unable to parse/ )
	end

	it "normalizes the expression before attempting to parse it" do
		parsed = described_class.parse( '\'";At  2014---01-01   14::00(' )
		expect( parsed.to_s ).to eq( 'at 2014-01-01 14:00' )
	end

	it "can parse the expression, offset from a different time" do
		parsed = described_class.parse( 'every 5 seconds ending in an hour' )
		expect( parsed.starting ).to eq( past )
		expect( parsed.ending ).to eq( past + 3600 )
	end

	it "is comparable" do
		p1 = described_class.parse( 'at 2pm' )
		p2 = described_class.parse( 'at 3pm' )
		p3 = described_class.parse( 'at 2:00pm' )

		expect( p1 ).to be < p2
		expect( p2 ).to be > p1
		expect( p1 ).to eq( p3 )
	end

	it "won't allow scheduling dates in the past" do
		expect {
			described_class.parse( 'on 1999-01-01' )
		}.to raise_error( Symphony::Metronome::TimeParseError, /schedule in the past/ )
	end

	it "doesn't allow intervals of 0" do
		expect {
			described_class.parse( 'every 0 seconds' )
		}.to raise_error( Symphony::Metronome::TimeParseError, /unable to parse/ )
	end


	context 'exact times and dates' do

		it 'at 2pm' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be
			expect( parsed.recurring ).to be_falsey
			expect( parsed.interval ).to be( 7200.0 )
		end

		it 'at 2:30pm' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 9000.0 )
		end

		it "pushes ambiguous times in today's past into tomorrow (at 11am)" do
			parsed = described_class.parse( 'at 11am' )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 82800.0 )
		end

		it 'on 2010-01-02' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 43200.0 )
		end

		it 'on 2010-01-02 12:00' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 86400.0 )
		end

		it 'on 2010-01-02 12:00:01' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 86401.0 )
		end

		it 'correctly timeboxes the expression' do
			parsed = described_class.parse( 'at 2pm' )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 7200.0 )
			expect( parsed.ending ).to be_nil
			expect( parsed.recurring ).to be_falsey
			expect( parsed.starting ).to eq( past + 7200 )
		end

		it 'sets the start time to the exact date' do
			parsed = described_class.parse( 'at 2pm'  )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_falsey
			expect( parsed.starting ).to eq( past + 7200 )
			expect( parsed.interval ).to be( 7200.0 )
		end
	end

	context 'one-shot intervals' do

		it 'in 30 seconds' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_falsey
			expect( parsed.interval ).to be( 30.0 )
		end

		it 'in 30 seconds from now' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 30.0 )
		end

		it 'in an hour from now' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 3600.0 )
		end

		it 'in 2.5 hours from now' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 9000.0 )
		end

		it 'in a minute' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 60.0 )
		end

		it 'correctly timeboxes the expression' do
			parsed = described_class.parse( 'in 30 seconds' )
			expect( parsed.valid ).to be_truthy
			expect( parsed.interval ).to be( 30.0 )
			expect( parsed.ending ).to be_nil
			expect( parsed.recurring ).to be_falsey
			expect( parsed.starting ).to eq( past + 30 )
		end

		it 'sets the start time to now if one is not specified' do
			parsed = described_class.parse( 'in 5 seconds'  )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_falsey
			expect( parsed.starting ).to eq( past + 5 )
			expect( parsed.interval ).to be( 5.0 )
		end

		it 'raises error for end specifications with non-recurring run times' do
			expect {
				described_class.parse( 'run at 2010-01-02 end at 2010-03-01' )
			}.to raise_error( Symphony::Metronome::TimeParseError, /non-deterministic/ )
		end
	end

	context 'repeating intervals' do

		it 'every 500 milliseconds' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 0.5 )
		end

		it 'every 30 seconds' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 30.0 )
		end

		it 'once an hour' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 3600.0 )
		end

		it 'once a minute' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 60.0 )
		end

		it 'once per week' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 604800.0 )
		end

		it 'every day' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 86400.0 )
		end

		it 'every other day' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 172800.0 )
		end

		it 'every 4th hour' do |example|
			parsed  = described_class.parse( example.description )
			parsed2 = described_class.parse( 'every 4 hours' )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 14400.0 )
			expect( parsed ).to eq( parsed2 )
		end

		it 'always sets a start time if one is not specified' do
			parsed = described_class.parse( 'every 5 seconds'  )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past )
			expect( parsed.interval ).to be( 5.0 )
		end
	end

	context 'repeating intervals with an expiration date' do

		it 'every day ending in 1 week' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 86400.0 )
			expect( parsed.ending ).to eq( past + 604800 )
		end

		it 'once a minute until 6pm' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 60.0 )
			expect( parsed.ending ).to eq( past + 3600 * 6 )
		end

		it 'once a day finishing in a week from now' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 86400.0 )
			expect( parsed.ending ).to eq( past + 604800 )
		end

		it 'once a day completing on 2010-02-01' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 86400.0 )
			expect( parsed.ending ).to eq( past + 2635200 )
		end

		it 'once a day end on 2010-02-01 00:00:10' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.interval ).to be( 86400.0 )
			expect( parsed.ending ).to eq( past + 2635210 )
		end

		it 'always sets a start time if one is not specified' do
			parsed = described_class.parse( 'every 5 seconds ending in 1 week'  )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past )
			expect( parsed.interval ).to be( 5.0 )
			expect( parsed.ending ).to eq( past + 604800 )
		end
	end

	context 'repeating intervals with only a start time' do

		it "won't allow explicit start times with non-recurring run times" do
			expect {
				described_class.parse( 'start at 2010-02-01 run at 2010-02-01' )
			}.to raise_error( Symphony::Metronome::TimeParseError, /use 'at \[datetime\]' instead/ )
		end

		it 'starting in 5 minutes, run once a second' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 300 )
			expect( parsed.interval ).to be( 1.0 )
		end

		it 'starting in a day execute every 3 minutes' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 86400 )
			expect( parsed.interval ).to be( 180.0 )
		end

		it 'start at 2010-01-02 execute every 1 minute' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 43200 )
			expect( parsed.interval ).to be( 60.0 )
		end

		it 'starting at 2010-01-02 09:00:00 run once a day' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 75600 )
			expect( parsed.interval ).to be( 86400.0 )
		end

		it 'always sets a start time if one is not specified' do
			parsed = described_class.parse( 'every 5 seconds'  )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past )
			expect( parsed.interval ).to be( 5.0 )
		end
	end

	context 'intervals with start and end times' do

		it 'beginning in 1 hour from now run every 5 seconds ending on 2010-01-02' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 3600 )
			expect( parsed.interval ).to be( 5.0 )
			expect( parsed.ending ).to eq( past + 43200 )
		end

		it 'starting in 1 hour, run every 5 seconds and finish at 3pm' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 3600 )
			expect( parsed.interval ).to be( 5.0 )
			expect( parsed.ending ).to eq( past + 3600 * 3 )
		end

		it 'begin in an hour run every 5 seconds and then stop at 3pm' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 3600 )
			expect( parsed.interval ).to be( 5.0 )
			expect( parsed.ending ).to eq( past + 3600 * 3 )
		end

		it 'mid-expression starts' do |example|
			parsed = described_class.parse( 'every 5 seconds starting in an hour for 3 hours' )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 3600 )
			expect( parsed.interval ).to be( 5.0 )
			expect( parsed.ending ).to eq( past + 3600 * 4 )
		end

		it 'post-expression starts' do |example|
			parsed = described_class.parse( 'every 5 seconds for 3 hours beginning in an hour' )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 3600 )
			expect( parsed.interval ).to be( 5.0 )
			expect( parsed.ending ).to eq( past + 3600 * 4 )
		end

		it 'start at 2010-01-02 10:00 and then run each minute for the next 6 days' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.valid ).to be_truthy
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 43200 + 36000 )
			expect( parsed.interval ).to be( 60.0 )
			expect( parsed.ending ).to eq( Time.parse('2010-01-02 10:00') + 86400 * 6 )
		end

		it 'raises an error if the end time is before the start' do
			expect {
				described_class.parse( 'starting at 2pm run once a minute end at 1pm' )
			}.to raise_error( Symphony::Metronome::TimeParseError, /ends before it begins/ )
		end
	end

	context 'intervals with a count' do

		it "won't allow count multipliers without an interval nor an end date" do
			expect {
				described_class.parse( 'run 10 times' )
			}.to raise_error( Symphony::Metronome::TimeParseError, /end date or interval is required/ )
		end

		it '10 times a minute for 2 days' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.multiplier ).to be( 10 )
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past )
			expect( parsed.interval ).to be( 6.0 )
			expect( parsed.ending ).to eq( past + 86400 * 2 )
		end

		it 'run 45 times every hour' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.multiplier ).to be( 45 )
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past )
			expect( parsed.interval ).to be( 80.0 )
			expect( parsed.ending ).to be_nil
		end

		it 'start at 2010-01-02 run 12 times and end on 2010-01-03' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.multiplier ).to be( 12 )
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 43200 )
			expect( parsed.interval ).to be( 7200.0 )
			expect( parsed.ending ).to eq( past + 86400 + 43200 )
		end

		it 'starting in an hour from now run 6 times a minute for 2 hours' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.multiplier ).to be( 6 )
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 3600 )
			expect( parsed.interval ).to be( 10.0 )
			expect( parsed.ending ).to eq( past + 3600 * 3 )
		end

		it 'beginning a day from now, run 30 times per minute and finish in 2 weeks' do |example|
			parsed = described_class.parse( example.description )
			expect( parsed.multiplier ).to be( 30 )
			expect( parsed.recurring ).to be_truthy
			expect( parsed.starting ).to eq( past + 86400 )
			expect( parsed.interval ).to be( 2.0 )
			expect( parsed.ending ).to eq( past + 1209600 + 86400 )
		end
	end

	context "when checking if it's okay to run" do

		it 'returns true if the interval is within bounds' do
			parsed = described_class.parse( 'at 2pm' )
			expect( parsed.fire? ).to be_falsey

			Timecop.freeze( past + 7200 ) do
				expect( parsed.fire? ).to be_truthy
			end
		end

		it 'returns nil if the ending (expiration) date has passed' do
			parsed = described_class.parse( 'every minute for an hour' )

			Timecop.freeze( past + 3601 ) do
				expect( parsed.fire? ).to be_nil
			end
		end

		it 'returns false if the starting window has yet to occur' do
			parsed = described_class.parse( 'starting in 2 hours run each minute' )
			expect( parsed.fire? ).to be_falsey
		end
	end
end

