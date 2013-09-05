require 'littlewire'
wire = LittleWire.connect
pin = :pin4
speed = 1
num_leds = 64

hue = 0.0

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
  # red = 1.0 + (Math.sin(hue) * 127)
  # green = 1.0 + (Math.sin(hue + ((Math::PI*2.0) / 3)) * 127)
  # blue = 1.0 + (Math.sin(hue - ((Math::PI*2.0) / 3)) * 127)
  # 
  # wire.ws2811(pin).send([Colorist::Color.from_rgb(red, green, blue)] * num_leds)
  # 
  # hue += 0.5
end