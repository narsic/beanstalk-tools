#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'
require 'ffi-ncurses'

begin

    include FFI::NCurses
    B = Beanstalk::Connection.new $*[0]

    def delta(v)
      v.to_i > 0 ? "+#{v}" : v.to_s
    end


    stdscr = initscr

    waddstr(stdscr, "Tubes running")

    tubes = $*[1..-1]
    previously={}
    loop do
        move 1,1
        waddstr(stdscr, "Time: #{Time.now.to_s}")

        tubes = B.list_tubes

        ts=B.stats_tube tubes[0]
        ts.delete('name')
        i = 0
        ts.keys.sort.each do |k|
            move(5, (i + 1) * 12) 
            i+=1
            waddstr(stdscr, k.gsub(/current-|tube-|cmd-|jobs-|/, ""))
        end

      attr_set A_NORMAL, 1, nil
      move 5, 15

      tube_index = 0
      tubes.each do |tube|
        deltas = previously[tube] || Hash.new(1)
        tube_index += 1

        move(6 + tube_index, 0)
        waddstr(stdscr, "%10.10s " % tube)
        ts=B.stats_tube tube
        ts.delete('name')
       
        i = 0 
        ts.keys.sort.each do |k|
            move(6 + tube_index , 12 * (i+1) )
            i+=1
            waddstr(stdscr, "%12.12s" % ts[k])
        end
        previously[tube] = ts
        
      end
      wrefresh stdscr
      move(0,0) 
      sleep 2 
    end

    endwin

rescue Exception => e
    endwin
    puts e.message  
    e.backtrace.each do |line|
        puts line
    end
end
