#!/usr/bin/env ruby
require 'thor'
require 'pp'
require 'littlewire'
require 'littlewire/gadgets/micronucleus'

class LittleWireUtility < Thor
  # for ruby 1.9 compatibility, we use this instead of ruby 2.0 __dir__
  Directory = defined?(__dir__) ? __dir__ : File.pathname(__FILE__)
  
  desc "install [version]", "Install a specific firmware on to the littlewire device"
  def install version = 'latest'
    path = File.join(Directory, "..", "firmware", "#{version}.hex")
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
    Dir[File.join(Directory, "..", "firmware", "*.hex")].each do |filename|
      puts File.basename(filename, '.hex')
    end
  end
  
  desc "version", "Which version of the ruby library is this?"
  def version
    puts "Library Version: #{LittleWire.version}"
    
    wire = LittleWire.connect
    puts "Device Firmware: #{wire.version}" if wire
    
    latest_path = File.join(Directory, "..", "firmware", "#{LittleWire::SupportedVersions.first}.hex")
    if LittleWire::SupportedVersions.index(wire.version) != 0 and File.exists? latest_path
      puts "An updated firmware is available, version #{LittleWire::SupportedVersions.first}"
      puts "To update, run:"
      puts "  littlewire.rb install #{LittleWire::SupportedVersions.first}"
      puts ""
      puts "If you bought your LittleWire as a kit from Seeed Studios, you may need to first"
      puts "install the Micronucleus bootloader as described on the littlewire.cc website."
      puts ""
    end
  end
  
  desc "racer", "Attach a Wii Nunchuck and play a game"
  def racer
    ruby_vm = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
    system(ruby_vm, File.join(Directory, '..', 'examples', 'i2c', 'nunchuck.rb'))
  end
end

LittleWireUtility.start(ARGV)

