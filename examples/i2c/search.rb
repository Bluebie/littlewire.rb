# This little example searches the i2c bus and lists all the responsive addresses
require 'littlewire'

wire = LittleWire.connect

# search all 128 (0 through 127 inclusive) i2c addresses
found = 128.times.select do |address|
  wire.i2c.start(address, :write)
end

puts "Active Addresses: #{found.inspect}"