require 'colorist'

# Output colours to ws2812 strips and other 800khz ws2811 led devices
# To use, simply set colours in the 'colors' array property as css color strings
# or Colorist::Color objects, then call #output(pin) to send it on it's way
# 
# Note that this requires firmware v1.2 and there is a maximum of 64 lights in the
# firmware at the time of writing. You can connect 64 leds to each of the digital
# pins on the LittleWire or Digispark device, and this enables you a total of
# 64 * 4 = 256 lights! Neato! Remember a USB port cannot supply enough current to
# power 256 lights at full brightness. Power usage is roughly (20ma * color_channel)
# per light. So 64 lights all lit full brightness white consumes 20*3*64 = 3.84 amps!
# Wow that's a lot of light for one little wire! And you can have four of those!
class LittleWire::WS2811
  attr_accessor :colors
  attr_accessor :pin
  attr_reader :wiring
  ColorTransformer = {
    rgb: ->(input) {
      input # passthrough
    },
    grb: ->(input) {
      Colorist::Color.from_rgb(input.g, input.r, input.b)
    },
    bgr: ->(input) {
      Colorist::Color.from_rgb(input.b, input.r, input.g)
    },
    gbr: ->(input) {
      Colorist::Color.from_rgb(input.g, input.b, input.r)
    },
    rbg: ->(input) {
      Colorist::Color.from_rgb(input.r, input.b, input.g)
    },
    greyscale: ->(input) {
      grey = (input.r + input.g + input.b) / 3 # average the colours
      Colorist::Color.from_rgb(grey, grey, grey)
    },
    # lookup chart
    florapixel_v1: :rbg,
    florapixels_v1: :florapixel_v1,
    ws2812: :rgb,
    florapixel_v2: :ws2812,
    florapixels_v2: :florapixel_v2,
    grayscale: :greyscale, # Woo English!
    white: :greyscale,
  }
  ChannelSize = 64 # LittleWire can store 64 values
  
  def initialize wire, default_pin = false # :nodoc:
    @wire = wire
    @pin = default_pin
    @colors = []
    @wiring = :rgb
    @wiring_map = ColorTransformer[:rgb]
  end
  
  # Set the pixel wiring style. The default :rgb is great for the little ws2812 LEDs
  # which have the chips built in as a little black cube inside the LED. This setting is for
  # other LEDs where the controller chip is outside the LED. In some of these LEDs the red,
  # green, and blue outputs of the controller chip connect to different colours of LEDs!
  # 
  # Of particular note, the original Adafruit Florapixels (now called version 1) can be modified
  # to run at the 800khz speed instead of 400khz by breaking off this leg on the chip on the back:
  # 
  #            ______
  #          -|o     |-
  #          -|      |-  <--- this one!
  #          -|      |-
  #          -|______|-
  #
  # This makes them compatible with LittleWire and cheap LED strips, but these florapixels are
  # wired bizarrely in RBG order. I rebuke thee, adafruit industries!! Also supposedly some
  # other version of the v1 florapixels used another different wiring and I don't think they're
  # labeled differently, so try it and see what works for you, or just give up and buy some
  # ws2812 strip from aliexpress - it's only like 30¢ per LED including shipping anyway!
  def wiring=(style)
    @wiring_map = style.to_sym
    # loop till we resolve symbol chain in to a real proc we can map colours through
    @wiring_map = ColorTransformer[@wiring_map] while @wiring_map.is_a? Symbol
    # if never exhausted lookup, you all get errors!!! ERRORS FOR EVERYONE!!!
    raise "Unknown Wiring Style #{style.inspect}! Must be one of " +
          "#{ColorTransformer.keys.map { |x| x.inspect }.join(', ')}" +
          " or a Proc which transforms a Colorist::Color" if @wiring_map == nil
    @wiring = style
  end
  
  # send colours to strip, optionally specifying a pin if not specified via
  #
  #   littlewire.ws2811(pin).output
  def output pin = nil
    colors_buffer = @colors.map { |i| @wiring_map[i.is_a?(Colorist::Color) ? i : i.to_color] }
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
  
  # Set strip to an array of colours, automatically outputting them to the strip immediately
  def send *colors
    @colors = colors.flatten
    output
  end
  alias_method :set, :send
  
  # Set the whole strip to be black! This can be nice at the start of your program, because
  # the strip starts out being whatever colours it was when it was powered up, which can be
  # random - this makes sure everything is black, at least up to the max 64 LEDs littlewire
  # supports per channel
  def black!
    send(['black'] * ChannelSize)
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

