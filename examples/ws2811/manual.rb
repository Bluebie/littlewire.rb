# Send up to 64 colours to a string of WS2812 LEDs or 800khz (version 2) Adafruit Flora NeoPixels
# Any 800khz mode ws2811 pixels will work
require 'littlewire'
wire = LittleWire.connect

puts DATA.read # print out the little ascii art thing at the end of this file
puts "Which pin to use for data output?"
print "Enter pin number: "
output_pin = gets.gsub(/[^0-9a-zA-Z]/, '').downcase

puts "Blacking out strip"
wire.ws2811(output_pin).black!

colors = []

# print "Enter 1st color: "
# wire.ws2811.colors = [gets.strip.to_color]
# wire.ws2811.output(output_pin) # output our first color

titles = ['1st', '2nd', '3rd']

63.times do |idx|
  print "Enter #{titles[idx] || "#{idx + 1}th"} color: "
  gotten = gets.strip
  break if gotten.empty?
  colors << gotten.to_color
  wire.ws2811(output_pin).send colors
end

puts "All done!"

__END__
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