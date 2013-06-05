require 'littlewire'
include Colorist
wire = LittleWire.connect
num_pixels = ARGV.first.to_i

loop do
  position = (Time.now.to_f / 60) % 1
  wire.ws2811.colors = num_pixels.times.map do |idx|
    brightness = Math.sin((position - (idx.to_f / num_pixels)) * Math::PI * 2) * 255
    Color.from_rgb(0, brightness.to_i, 0)
  end
  
  wire.ws2811.output :pin4
  
  sleep 1.0 / 60.0
end

