# A little blinky test to show how to make stuff happen with a littlewire in ruby!
#
# To get started, plug an LED in to the ISP cable between ground and Pin 3 (they're next to each other)
require '../lib/littlewire.rb'

wire = LittleWire.connect

# set pin3 to an input, so our LED doesn't burn out without a resistor
wire.pin_mode :pin3 => :input

loop do
  wire[:d3] = true # set the LED on for half a second
  sleep 0.5
  wire[:d3] = false # set the LED off for half a second
  sleep 0.5
end
