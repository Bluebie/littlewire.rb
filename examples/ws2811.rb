# Send up to 64 colours to a string of WS2812 LEDs or 800khz (version 2) Adafruit Flora NeoPixels
# Any 800khz mode ws2811 pixels will work
require 'littlewire'
wire = LittleWire.connect

puts DATA.read # print out the little ascii art thing at the end of this file
puts "Which pin to use for data output?"
print "Enter pin number: "
output_pin = gets.gsub(/[^0-9]/, '').to_i

print "Enter 1st color: "
wire.ws2811.colors = [gets.strip.to_color]
wire.ws2811.output(output_pin) # output our first color

titles = ['1st', '2nd', '3rd']

63.times do |idx|
  print "Enter #{titles[idx + 1] || "#{idx + 2}th"} color: "
  gotten = gets.strip
  break if gotten.empty?
  # add colour to array
  wire.ws2811.colors.push gotten.to_color
  wire.ws2811.output(output_pin) # output the colours to the string
end

puts "All done!"

__END__
 LittleWire connector:   |   Digispark Board:
        /-----\          |         _________
  pin_1 | o o | vcc      |   _____|        o| ds5
  pin_2 | o o | pin 4    |  |-----         o| (usb - not available)
  pin_3 | o o | gnd      |  |-----         o| (usb - not available)
        \-----/          |  |-----         o| ds2
                            |-----         o| ds1
                                  |_o_o_o__o| ds0
                                    5 g v
                                    v n c
                                      d c