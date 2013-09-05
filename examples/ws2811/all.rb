# Send up to 64 colours to a string of WS2812 LEDs or 800khz (version 2) Adafruit Flora NeoPixels
# Any 800khz mode ws2811 pixels will work
require 'littlewire'
wire = LittleWire.connect

if wire == nil
  puts "Couldn't find an attached LittleWire device"
  exit
end

if ARGV.length != 2
  puts DATA.read # print out the little ascii art help
  exit
end

pin = ARGV[0].gsub(/[^0-9a-zA-Z]/, '').downcase
color = ARGV[1]

puts "Setting 64 pixels connected to #{pin} to be #{color}"
wire.ws2811(pin).send([color] * 64)

puts "All done!"

__END__

all.rb sets 64 pixels connected to a littlewire (or digispark) pin to
a specific colour. You can specify this colour by CSS name 'red'
or by web-style hex code '#ff0000', or with CSS-style RGB constructs
'(rgb(255, 0, 0)'. Run all.rb with two arguments - the output pin name
followed by the colour.

 LittleWire connector:   |   Digispark Board:
       /-----\         |         _________
  pin1 | o o | vcc     |   _____|        o| ds5
  pin2 | o o | pin4    |  |-----         o| (usb - not available)
  pin3 | o o | gnd     |  |-----         o| (usb - not available)
       \-----/         |  |-----         o| ds2
                          |-----         o| ds1
                                |_o_o_o__o| ds0
                                  5 g v
                                  v n c
                                    d c

Example: ruby all.rb pin4 aqua
