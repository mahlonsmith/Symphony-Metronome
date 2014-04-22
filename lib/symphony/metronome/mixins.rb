# -*- ruby -*-
#encoding: utf-8
# vim: set nosta noet ts=4 sw=4:

require 'symphony' unless defined?( Symphony )
require 'symphony/metronome' unless defined?( Symphony::Metronome )


module Symphony::Metronome

	# Functions for time calculations
	module TimeFunctions

		###############
		module_function
		###############

		### Calculate the (approximate) number of seconds that are in +count+ of the
		### given +unit+ of time.
		###
		def calculate_seconds( count, unit )
			return case unit
			when :seconds, :second
				count
			when :minutes, :minute
				count * 60
			when :hours, :hour
				count * 3600
			when :days, :day
				count * 86400
			when :weeks, :week
				count * 604800
			when :fortnights, :fortnight
				count * 1209600
			when :months, :month
				count * 2592000
			when :years, :year
				count * 31557600
			else
				raise ArgumentError, "don't know how to calculate seconds in a %p" % [ unit ]
			end
		end
	end # module TimeFunctions


	# Refinements to Numeric to add time-related convenience methods
	module TimeRefinements
		refine Numeric do

			### Number of seconds (returns receiver unmodified)
			def seconds
				return self
			end
			alias_method :second, :seconds

			### Returns number of seconds in <receiver> minutes
			def minutes
				return TimeFunctions.calculate_seconds( self, :minutes )
			end
			alias_method :minute, :minutes

			### Returns the number of seconds in <receiver> hours
			def hours
				return TimeFunctions.calculate_seconds( self, :hours )
			end
			alias_method :hour, :hours

			### Returns the number of seconds in <receiver> days
			def days
				return TimeFunctions.calculate_seconds( self, :day )
			end
			alias_method :day, :days

			### Return the number of seconds in <receiver> weeks
			def weeks
				return TimeFunctions.calculate_seconds( self, :weeks )
			end
			alias_method :week, :weeks

			### Returns the number of seconds in <receiver> fortnights
			def fortnights
				return TimeFunctions.calculate_seconds( self, :fortnights )
			end
			alias_method :fortnight, :fortnights

			### Returns the number of seconds in <receiver> months (approximate)
			def months
				return TimeFunctions.calculate_seconds( self, :months )
			end
			alias_method :month, :months

			### Returns the number of seconds in <receiver> years (approximate)
			def years
				return TimeFunctions.calculate_seconds( self, :years )
			end
			alias_method :year, :years


			### Returns the Time <receiver> number of seconds before the
			### specified +time+. E.g., 2.hours.before( header.expiration )
			def before( time )
				return time - self
			end


			### Returns the Time <receiver> number of seconds ago. (e.g.,
			### expiration > 2.hours.ago )
			def ago
				return self.before( ::Time.now )
			end


			### Returns the Time <receiver> number of seconds after the given +time+.
			### E.g., 10.minutes.after( header.expiration )
			def after( time )
				return time + self
			end


			### Return a new Time <receiver> number of seconds from now.
			def from_now
				return self.after( ::Time.now )
			end

		end # refine Numeric
	end # module TimeRefinements

end # module Symphony::Metronome


