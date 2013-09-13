# This little example searches the i2c bus and lists all the responsive addresses
require 'littlewire'

wire = LittleWire.connect
puts "Active Addresses: #{wire.i2c.search.inspect}"
