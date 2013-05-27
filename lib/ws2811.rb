require 'colorist'

# Output colours to ws2812 strips and other 800khz ws2811 led devices
# To use, simply set colours in the 'colors' array property as css color strings
# or Colorist::Color objects, then call #output(pin) to send it on it's way
# 
# Note that this requires firmware v1.2 which is not yet released and there is a
# maximum of 64 lights in the firmware at the time of writing
# 
# Also note that you can connect 64 leds to each of the digital pins on the LittleWire
# or Digispark device, and this enables you a total of 64 * 4 = 256 lights! Neato!
class LittleWire::WS2811
  attr_accessor :colors
  attr_accessor :pin
  
  
  def initialize wire, default_pin = false # :nodoc:
    @wire = wire
    @pin = default_pin
    @colors = []
  end
  
  # send colours to strip, optionally specifying a pin if not specified via
  # littlewire.ws2811(pin).output
  def output pin = nil
    colors_buffer = @colors.map { |i| i.is_a?(Colorist::Color) ? i : i.to_color }
    output_pin = @wire.get_pin(LittleWire::DigitalPinMap, pin || @pin)
    raise "Must specify output pin for ws2811 strip" unless output_pin.is_a? Integer
    
    until colors_buffer.empty?
      
      if colors_buffer.length > 1
        color = colors_buffer.shift
        
        @wire.control_transfer(
          function: :ws2812_preload,
          wIndex: color.b << 8 | color.r,
          wValue: color.g << 8
        )
      elsif colors_buffer.length == 1
        color = colors_buffer.shift
        
        @wire.control_transfer(
          function: :ws2812_write,
          wIndex: color.b << 8 | color.r,
          wValue: color.g << 8 | output_pin
        )
      end
    end
  end
end

