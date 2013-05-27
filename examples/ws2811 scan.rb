require '../lib/littlewire.rb'
wire = LittleWire.connect
num_pixels = ARGV.first.to_i

lit = 0
loop do
  
  text_output = ['-'] * num_pixels
  text_output[lit] = '*'
  puts text_output.join
  
  wire.ws2811.colors = num_pixels.times.map do |idx|
    if idx == lit
      'white'.to_color
    else
      'black'.to_color
    end
  end
  wire.ws2811.output :pin1
  
  lit += 1
  lit %= num_pixels
  
  sleep 0.01
end