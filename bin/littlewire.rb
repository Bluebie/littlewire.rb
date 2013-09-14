#!/usr/bin/env ruby
$:.unshift File.dirname(__FILE__) + "/../lib"
require 'thor'
require 'pp'
require_relative '../lib/littlewire'
require_relative '../lib/gadgets/micronucleus'

class LittleWireUtility < Thor
  desc "install [version]", "Install a specific firmware on to the littlewire device"
  def install version = 'latest'
    path = File.join(__dir__, "..", "firmware", "#{version}.hex")
    raise "Unknown Version" unless File.file? path
    
    data = HexProgram.new(open path).binary
    
    retried = false
    begin
      puts "Will upload to a littlewire which has been updated with the micronucleus bootloader, or to a digispark."
      puts "Plug in micronucleus device now: (waiting)"
      sleep 0.25 while Micronucleus.all.length == 0
    
      nucleus = Micronucleus.all.first
      puts "Attached to device: #{nucleus.inspect}"
    
      sleep(0.25) # some time to think?
      puts "Writing program in to device's memory"
      nucleus.program = data

      puts "Great! Starting new littlewire firmware..."
      nucleus.finished # let thinklet know it can go do other things now if it likes
    rescue LIBUSB::ERROR_IO => err
      unless retried
        retried = true
        retry
      end
      raise err
    end
    
    puts "All done!"
    puts "If littlewire doesn't automatically appear in a few seconds, unplug and replug device from USB port"
  end
  
  desc "firmwares", "List all versions which can be installed via install command"
  def firmwares
    puts "Available LittleWire Firmware:"
    Dir[File.join(__dir__, "..", "firmware", "*.hex")].each do |filename|
      puts File.basename(filename, '.hex')
    end
  end
  
  desc "version", "Which version of the ruby library is this?"
  def version
    puts "Current Version: " + LittleWire.version
  end
end

LittleWireUtility.start(ARGV)

