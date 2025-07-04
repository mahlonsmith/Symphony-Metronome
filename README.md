# Metronome

home
: https://code.martini.nu/mahlon/symphony-metronome

docs
: https://martini.nu/docs/symphony-metronome

github_mirror
: https://github.com/mahlonsmith/symphony-metronome



## Description

Metronome is an interval scheduler and task runner.  It can be used locally as a
cron replacement, or as a network-wide job executor.  It is intended to be run
alongside Symphony, a Ruby AMQP event consumer.

[![Gem Version](https://badge.fury.io/rb/symphony-metronome.svg)](https://badge.fury.io/rb/symphony-metronome)

Events are stored via simple database rows, and optionally themselves managed
via AMQP events.  Interval/time values are expressed with intuitive English
phrases, ie.: 'at 2pm', or 'Starting in 20 minutes, run every 10 seconds and
then finish in 2 days', or 'execute 12 times during the next minute'.

## Synopsis

Here's an example of a simple cron clone:

```
#!ruby

require 'symphony/metronome'

Symphony.load_config

Symphony::Metronome.run do |opts, id|
	Thread.new do
		pid = fork { exec opts.delete('command') }
		Process.waitpid( pid )
	end
end
```


And here's a simplistic timed AMQP message broadcaster, using existing Symphony
connection information:

```
#!ruby

require 'symphony/metronome'

Symphony.load_config

Symphony::Metronome.run do |opts, id|
	key = opts.delete( 'routing_key' ) or next
	exchange = Symphony::Queue.amqp_exchange
	exchange.publish( 'hi from Metronome!', routing_key: key )
end
```

## Adding Actions

There are two primary components to Metronome -- getting actions into
its database, and performing some task with those actions when the time
is appropriate.

By default, Metronome will start up an AMQP listener, attached to your
Symphony exchange, and wait for new scheduling messages.  There are two
events it will take action on:

metronome.create:

	Create a new scheduled event.  The payload should be a hash.  An
	'expression' key is required, that provides the interval description.
	Anything additional is serialized to 'options', that are passed to the
	block when the interval fires.  You can populate it with anything
	your task requires to execute.

metronome.delete:

	The payload is the row ID of the action.  Metronome removes it from
	the database.

If you'd prefer not to use the AMQP listener, you can put actions into
Metronome using any database methodology you please.  When the daemon
starts up or receives a HUP signal, it will re-read and schedule out
upcoming work.


## Options

Metronome uses
[Configurability](https://rubygems.org/gems/configurability) to determine
behavior.  The configuration is a [YAML](http://www.yaml.org/) file.  It
shares AMQP configuration with Symphony, and adds metronome specific
controls in the 'metronome' key.

	metronome:
		splay: 0
		listen: true
		db: sqlite:///tmp/metronome.db


### splay

Randomize all start times for actions by this many seconds on either
side of the original execution time.  Defaults to none.

### listen

Start up an AMQP listener using Symphony configuration, for remote
administration of schedule events.  Defaults to true.

### db

A [Sequel](https://rubygems.org/gems/sequel) connection URI.  Currently,
Metronome is tested under SQLite and PostgreSQL.  Defaults to a SQLite
file at /tmp/metronome.db.


## Scheduling Examples

Note that Metronome is designed as an interval scheduler, not a
calendaring app.  It doesn't have any concepts around phrases like "next
tuesday", or "the 3rd sunday after christmas".  If that's what you're
after, check out the [chronic](http://rubygems.org/gems/chronic)
library instead.

Here are a small set of example expressions.  Feel free to use the
*metronome-exp* utility to get a feel for what Metronome anticipates.

```
in 30.5 minutes
once an hour
every 15 minutes for 2 days
at 2014-05-01
at 2014-04-01 14:00:25
at 2pm
starting at 2pm once a day
start in 1 hour from now run every 5 seconds end at 11:15pm
every other hour
run every 7th minute for a day
once a day ending in 1 week
run once a minute for an hour starting in 6 days
10 times a minute for 2 days
run 45 times every hour
30 times per day
start at 2010-01-02 run 12 times and end on 2010-01-03
starting in an hour from now run 6 times a minute for 2 hours
beginning a day from now, run 30 times per minute and finish in 2 weeks
execute 12 times during the next 2 minutes
once a minute beginning in 5 minutes
```

In general, you can use reasonably intuitive phrasings.  Capitalization,
whitespace, and punctuation doesn't matter.  When describing numbers,
use digit/integer form instead of words, ie: '1 hour' instead of 'one
hour'.


## Installation

```
gem install symphony-metronome
```

## Contributing

You can check out the source via Git/Jujutsu from its
[home repo](https://code.martini.nu/mahlon/symphony-metronome),
or its [github mirror](https://github.com/mahlonsmith/Symphony-Metronome).

After checking out the source, run:

    $ gem install -Ng
    $ rake setup

This will install dependencies, and do any other necessary setup for
development.

Please report any issues
[here](https://code.martini.nu/mahlon/symphony-metronome/issues).


## Authors

- Mahlon E. Smith <mahlon@martini.nu>


## License

Copyright (c) 2014-2023 Mahlon E. Smith
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
