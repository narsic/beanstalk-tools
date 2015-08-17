#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

B = Beanstalk::Connection.new $*[0]

tubes = $*[1..-1]
tubes = B.list_tubes if tubes.empty?

def delta(v)
  v.to_i > 0 ? "+#{v}" : v.to_s
end


ts=B.stats_tube tubes[0]
ts.delete('name')
titles = "%10.10s " % ""
ts.keys.sort.each do |k|
  titles += "%10.10s " % k.gsub(/-/,'').gsub(/current/, '').gsub(/jobs/, '')
end

previously={}
loop do
  puts "#{Time.now.to_s}"
  puts titles
  tubes.each do |tube|
    print "%10.10s " % tube
    ts=B.stats_tube tube
    ts.delete('name')
    deltas = previously[tube] || Hash.new(0)
    ts.keys.sort.each do |k|
      print "%10.10s " % "#{ts[k]}"  #{delta(ts[k] - deltas[k])}"
    end
    puts ""
    previously[tube] = ts
  end
  sleep 5 
end
