require 'littlewire'
wire = LittleWire.connect
pin = :pin1
speed = 1
num_leds = 64

loop do
  puts "red"
  wire.ws2811.colors = ['red'] * num_leds
  wire.ws2811.output pin
  sleep speed
  puts "green"
  wire.ws2811.colors = ['green'] * num_leds
  wire.ws2811.output pin
  sleep speed
  puts "blue"
  wire.ws2811.colors = ['blue'] * num_leds
  wire.ws2811.output pin
  sleep speed
end