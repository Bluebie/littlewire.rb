require 'littlewire'
wire = LittleWire.connect
pin = :pin4
speed = 1
num_leds = 64

loop do
  puts "red"
  wire.ws2811(pin).send(['red'] * num_leds)
  sleep speed
  
  puts "green"
  wire.ws2811(pin).send(['green'] * num_leds)
  sleep speed
  
  puts "blue"
  wire.ws2811(pin).send(['blue'] * num_leds)
  sleep speed
end