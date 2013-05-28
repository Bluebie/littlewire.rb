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
        preload(colors_buffer.shift)
        
      elsif colors_buffer.length == 1
        write(colors_buffer.shift, output_pin)
        
      end
    end
  end
  
  def send *colors
    @colors = colors.flatten
    output
  end
  alias_method :set, :send
  
  def black!
    @colors = ['black'] * 64
    output
  end
  
  private
  
  # push another set of rgb values to the buffer
  def preload color
    @wire.control_transfer(
      function: :ws2812,
      wIndex: color.b.to_i << 8 | color.r.to_i,
      wValue: color.g.to_i << 8 | 0x20
    )
  end
  
  # send buffer from littlewire to LEDs
  def flush pin
    @wire.control_transfer(
      function: :ws2812,
      wIndex: 0, wValue: pin.to_i | 0x10
    )
    output_delay(@colors.length)
  end
  
  # optimises preload followed by flush in to a single usb call
  #   def write color, pin
  #     preload color
  #     flush pin
  #   end
  def write color, pin
    @wire.control_transfer(
      function: :ws2812,
      wIndex: color.b.to_i << 8 | color.r.to_i,
      wValue: color.g.to_i << 8 | pin.to_i | 0x30
    )
    output_delay(@colors.length)
  end
  
  # wait as long as it will take for the message to output to the LED strip, so we don't make
  # any more USB requests while the device is busy flushing pixels with interrupts disabled
  def output_delay(pixels)
    # each pixel consumes 30us for it's data, plus a little extra for reset
    sleep((0.00003 * pixels) + 0.001)
  end
end

