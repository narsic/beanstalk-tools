#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

require 'optparse'
require 'net/http'
require 'net/https'

WARN = 0
ERROR = -1
lastState = nil
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: beanstalk-jobs.rb [options]"
  opts.on("-h", "--host HOST", "beanstalk host") do | host|
    options[:host] = host
  end
  
  opts.on("--port", "--port PORT", "beanstalk port") do | port |
    options[:port] = port
  end
  
  opts.on("--error", "--error [ERROR_LIMIT]", Integer, "max items in tube before error") do | error_limit|
    options[:error] = error_limit
  end
  
  opts.on("--warn", "--warn [WARN_LIMIT]", Integer, "max items in tube before warn") do | warn_limit|
    options[:warn] = warn_limit
  end  

  opts.on("--webhook", "--webhook [WEBHOOK_URL]", String, "Webhook url to call, put http://yourdomain.com/server_message=\{msg\} ") do | webhook|
    options[:webhook] = webhook
  end  
  
  opts.on("--tube", "--tube TUBE", "beanstalk tube") do | tube |
    options[:tube] = tube 
  end
    
end

begin 
  optparse.parse!

  mandatory = [:host, :port, :error, :warn]
  missing = mandatory.select{ |param| options[param].nil? }
  if missing.any?
    puts "Missing options: #{missing.join(', ')}"
    puts optparse
    exit
  end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse 
  exit
end

def callWebHook(url, msg)
  msg = "Beanstalkd: " + msg
  msg = URI::encode(msg)
  url = url.gsub("{msg}", msg)
  url = URI.parse(url)
  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true
  req = Net::HTTP::Get.new(url.to_s)
  res = https.request(req)
  puts res.body
end

connection = Beanstalk::Connection.new("#{options[:host]}:#{options[:port]}")

loop do
  if options[:tube]
    begin
      stats = connection.stats_tube(options[:tube])
    rescue Beanstalk::NotFoundError
      puts "Tube #{options[:tube]} not found." 
      exit
    end
  else
    stats = connection.stats
  end

  jobs = stats['current-jobs-ready'] + stats['current-jobs-delayed']

  if jobs > options[:error]
    msg = "CRITICAL - Too many outstanding jobs:  #{jobs}.  Error limit: #{options[:error]} | 'Ready Jobs'=#{jobs}"
    if not lastState == ERROR
      lastState = ERROR
      callWebHook(options[:webhook], msg)
    end
  elsif jobs > options[:warn]
    msg = "WARNING - Too many outstanding jobs:  #{jobs}.  Warn limit: #{options[:warn]} | 'Ready Jobs'=#{jobs}"
    if not lastState == WARN
      lastState = WARN
      callWebHook(options[:webhook], msg)
    end
  else
    msg = "OK - #{jobs} jobs found. | 'Ready Jobs' = #{jobs}"
    if lastState == ERROR
      lastState = nil
      callWebHook(options[:webhook], msg)
    end
  end

  puts msg
  if ARGV[0] === "exit"
    exit 0
  end
  sleep 30 
end

