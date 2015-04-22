#!/usr/bin/env ruby

# A command line script used to test support for concurrent
# access to sessions.

require 'date'
require 'net/http'
require 'uri'
require 'json'

DEBUG = false
DEFAULT_UPDATE_COUNT = 10
THREAD_INTERVAL = 0
REQUEST_INTERVAL = 0


##
#  === Test Runner ===
##

class SessionConcurrencyTester
  def initialize(servers, update_count)
    @servers = servers
    @update_count = update_count

    @threads = []
    @cookie = nil

    @expected_session_attrs = {}
    @succeeded = false
  end

  def get_cookie
    return nil if @servers.empty?

    server_uri = URI.parse("http://#{@servers[0]}")
    http = Net::HTTP.new(server_uri.host, server_uri.port)

    request = Net::HTTP::Get.new("/")
    response = http.request(request)

    case response
    when Net::HTTPOK
      puts "Retrieved cookie: #{response['set-cookie']}"
      @cookie = response['set-cookie']
    else
      puts "WARNING: Cookie Lookup Failed: #{server_uri} - #{response.code}"
      @cookie = nil
    end

    return @cookie
  end

  def run
    @succeeded = false && return if !@cookie
    puts "== Running test with cookie: #{@cookie}" if DEBUG

    @servers.each_with_index do |server, index|
      @threads << Thread.new do
        puts "== Starting test of server: #{server}" if DEBUG
        exercise_server(server, index)
        puts "== Completed test of server: #{server}" if DEBUG
      end

      sleep(THREAD_INTERVAL)
    end
  end

  def exercise_server(server, server_index)
    server_uri = URI.parse("http://#{server}")
    server_port = server_uri.port
    http = Net::HTTP.new(server_uri.host, server_port)

    @update_count.times do |i|
      request = Net::HTTP::Put.new("/session")
      request['cookie'] = @cookie

      key = "#{server_index}-#{server}-#{i}"
      timestamp = DateTime.now.to_time.to_f

      request.body = "key=#{key}&value=#{timestamp}"
      @expected_session_attrs[key] = timestamp

      response = http.request(request)
      case response
      when Net::HTTPOK
        puts "Attempted to set '#{key}' key via server '#{server}'"
        puts "--- Session Update Result: #{response.code} - #{response.to_hash}" if DEBUG
      else
        puts "WARNING: Failed to set '#{key}' key via server '#{server}': #{response.code} - #{response.body}"
      end

      sleep(REQUEST_INTERVAL)
    end
  end

  def wait_for_completion
    @threads.each { |thread| thread.join }
  end

  def validate_results
    @succeeded = false && return if @servers.empty?

    server_uri = URI.parse("http://#{@servers[0]}")
    http = Net::HTTP.new(server_uri.host, server_uri.port)

    request = Net::HTTP::Get.new("/session")
    request['cookie'] = @cookie
    response = http.request(request)

    case response
    when Net::HTTPOK
      session_json = response.body
      puts "Resulting Session: #{session_json}" if DEBUG
      session = JSON.parse(session_json)
      session_body = session['content']

      missing_attrs = @expected_session_attrs.select do |key, value|
        !session_body[key] || !session_body[key].eql?(value.to_s)
      end

      @succeeded = missing_attrs.empty?

      if !@succeeded
        puts "WARNING: Failed to set the following keys in the session: #{missing_attrs.keys.inspect}"
      end
    else
      puts "WARNING: Session lookup from '#{@servers[0]}' failed: #{response.code} - #{response.body}"
    end
  end

  def succeeded?
    @succeeded
  end

end



##
#  === Command Line Support ===
##

def show_help
  puts "Usage: concurrency-test <servers> <update-count> <arguments ...>\n"
  puts "  server-ports: A comma separated list of servers (hostnames or addresses including port)\n" +
    "    on which to run this test.\n"
  puts "  update-count: The number of session updates to be performed through each server.\n\n"
  puts "This test utility will run a series of session updates on the set of servers specified.\n" +
    "The same session will be used across all servers' requests. Each server will be updated in\n" +
    "parallel to evaluate the ability of the system to handle concurrent updates on a session.\n" +
    "Each update will add a new key to the session. Upon completion of all updates, the session\n" +
    "will be retrieved to verify that all updates were properly stored in the session.\n\n"
end


# Sanity check
if ARGV.length == 0
    show_help
    exit 1
end


# Extract Input Parameters
servers = ARGV[0].split(',')
puts "Servers: #{servers.inspect}" if DEBUG

update_count = ARGV[1].to_i
if update_count <= 0
  update_count = DEFAULT_UPDATE_COUNT
end
puts "Update Count: #{update_count}" if DEBUG

# Execute Test
tester = SessionConcurrencyTester.new(servers, update_count)

puts "# Retrieving Cookie" if DEBUG
if !tester.get_cookie
  puts "# Failed to get cookie." if DEBUG
  exit 2
end

puts "# Starting Test"
tester.run
tester.wait_for_completion
tester.validate_results
puts "# Completed Test" if DEBUG

if !tester.succeeded?
  puts "# Failed to Detect All Session Updates"
  exit 2
else
  puts "# Test Completed Successfully"
  exit 0
end
