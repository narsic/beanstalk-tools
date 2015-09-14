# Beanstalk Utilities

Here is a small collection of tools for watching, monitoring, and
manipulating beanstalkd.
These tools require Ruby and the beanstalk-client gem.

## Interactive Commands

Interactive commands are in the bin directory.

### beanstalk-stats.rb

beanstalk-stats.rb gives you a feel for how fast things are going in and out
of your queue.

    usage: beanstalk-stats.rb host:11300 host2:11300 [...]

### beanstalk-queue-stats.rb

beanstalk-queue-stats.rb watches a single beanstalk instance and shows you
which tubes contain elements, and how fast they're changing.

    usage: beanstalk-queue-stats.rb host:11300

### beanstalk-cleanup.rb

beanstalk-cleanup.rb is a continuously edited one-off script to help clean
stuff out of queues.  It pulls stuff out of the queue and defers, buries, or
deletes items based on regexes over the content.

    usage: vi beanstalk-cleanup.rb
           # edit the awesome hard-coded bury and delete rules
           beanstalk-cleanup.rb host:11300

### beanstalk-export.rb

beanstalk-export.rb will export all of the jobs from a server.  You
can use it to perform a server upgrade, or migrate all of the jobs
from one server another.

You *should* put the server in draining mode (send signal `USR1`)
before starting this to ensure new jobs aren't getting queued.  You
may also consider shutting down your workers since it may otherwise
cause jobs to be executed prematurely.

Note that the following job attributes are preserved:

* tube
* delay
* priority
* ttr
* body

Anything else (e.g. buried status or number of failures) is lost in
translation.

    usage: beanstalk-export.rb host:11300 > export.yml

### beanstalk-import.rb

beanstalk-import.rb is a tool to complement to beanstalk-export.rb by
allowing the export to be loaded into another server.

    usage: beanstalk-import.rb export.yml host:11300

## Nagios Monitoring Scripts

### beanstalk-count.rb

Ensures the named statistic in the named tube is below the warning/error definitions.

    usage: beanstalk-count.rb --host localhost --port 11300 --warn 10 --error 20 --stat <stat> --tube <tube>

warn and error respectively set the maximum number of named statistic
before a warning or error is issued.
Optionally the --tube argument can be used to restrict 
statistics to a particular tube.  If --tube is not used, totals from all tubes (default) will be used.
Available stats:
 - "current-jobs-urgent" is the number of ready jobs with priority < 1024 in
   this tube.

 - "current-jobs-ready" is the number of jobs in the ready queue in this tube.

 - "current-jobs-reserved" is the number of jobs reserved by all clients in
   this tube.

 - "current-jobs-delayed" is the number of delayed jobs in this tube.

 - "current-jobs-buried" is the number of buried jobs in this tube.

 - "total-jobs" is the cumulative count of jobs created in this tube in
   the current beanstalkd process.

 - "current-using" is the number of open connections that are currently
   using this tube.

 - "current-waiting" is the number of open connections that have issued a
   reserve command while watching this tube but not yet received a response.

 - "current-watching" is the number of open connections that are currently
   watching this tube.

 - "pause" is the number of seconds the tube has been paused for.

 - "cmd-delete" is the cumulative number of delete commands for this tube

 - "cmd-pause-tube" is the cumulative number of pause-tube commands for this
   tube.

 - "pause-time-left" is the number of seconds until the tube is un-paused.
 
 **From https://github.com/kr/beanstalkd/blob/master/doc/protocol.txt**

### beanstalk-jobs.rb

Ensures the number of jobs in the default tube fall within a reasonable range.

    usage: beanstalk-jobs.rb --host localhost --port 11300 --warn 10 --error 20

warn and error respectively set the maximum number of jobs found
before a warning or error is issued. Optionally the --tube argument can be used to restrict 
statistics to a particular tube.

### beanstalk-workers.rb

Ensures that the number of workers within the queue is within range.

    usage: beanstalk-workers.rb  --host localhost --port 11300 --warn 10 --error 5

warn and error respectively specify the minimum workers
that should be in place before a warning or error is issued.
Optionally the --tube argument can be used to restrict 
statistics to a particular tube.

### beanstalk-rate.rb

Ensures the growth rate of a particular stat is within range.

    usage: beanstalk-rate.rb host:11300 --host localhost --port 11300 --warnlow 0.05 --errorlow 0.01   --warnhigh 0.75 --errorhigh 0.99 --stat stat_name

All min and max values are required and are interpreted as floats.  The rates
are expressed as units per second. Optionally the --tube argument can be used to restrict 
statistics to a particular tube.
