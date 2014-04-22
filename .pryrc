#!/usr/bin/ruby -*- ruby -*-

require 'pathname'

begin
	$LOAD_PATH.unshift( Pathname(__FILE__).dirname + 'lib' )
	require 'symphony'
	require 'symphony/metronome'

rescue => e
	$stderr.puts "Ack! Libraries failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end

