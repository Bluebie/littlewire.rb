# A little library for a little wire, by Bluebie
# Provides an arduino or wiring style interface to the LittleWire device's IO features
# and provides a nicer invented ruby-style interface also.
require 'libusb'
class LittleWire; end
require_relative 'digital'
require_relative 'analog'
require_relative 'hardware-pwm'
require_relative 'software-pwm'
require_relative 'servo'
require_relative 'spi'
require_relative 'i2c'
require_relative 'one-wire'

# LittleWire class represents LittleWire's connected to your computer via USB
# 
# Most of the time you'll only have one LittleWire - in this case, use LittleWire.connect to get
# ahold of your wire. If you have more than one, you can use LittleWire.all to fetch an array of them
class LittleWire
  include Digital
  include Analog
  include HardwarePWM
  include SoftwarePWM
  include Servo
  
  # pin name to numeric internal code maps
  DigitalPinMap = { # maps common names to bit positions in PORTB
    pin1: 1, d1: 1, miso:  1, pwm_b: 1, pwm_2: 1,
    pin2: 2, d2: 2, sck:   2,
    pin3: 5, d3: 5, reset: 5,
    pin4: 0, d4: 0, mosi:  0, pwm_a: 0, pwm_1: 0 }
  AnalogPinMap = { # maps common names to switch index in littlewire firmware
    a1: 0, adc_1: 0, reset: 0, pin3: 0, d3: 0,
    a2: 1, adc_2: 1, sck:   1, pin2: 1, d2: 1,
    temperature: 2, temp: 2 }
  HardwarePWMPinMap = { # maps common pin names to @hardware_pwm array index
    pwm_b: 1, pwm_1: 1, d1: 1, pin1: 1, miso: 1,
    pwm_a: 0, pwm_2: 0, d4: 0, pin4: 0, mosi: 0 }
  SoftwarePWMPinMap = { # TODO: figure out which pins these are
    softpwm_1: 0, softpwm_a: 0, pin4: 0, d4: 0, mosi: 0, pwm_a: 0, pwm_1: 0,
    softpwm_2: 1, softpwm_b: 1, pin1: 1, d1: 1, miso: 1, pwm_b: 1, pwm_2: 1,
    softpwm_3: 2, softpwm_c: 2, pin2: 2, d2: 2, sck: 2 }
  GenericPinMap = { # generic pinmap used by [] and []= methods to refer to anything
    d1: [:digital, :pin1],
    d2: [:digital, :pin2],
    d3: [:digital, :pin3],
    d4: [:digital, :pin4],
    pin1: [:digital, :pin1],
    pin2: [:digital, :pin2],
    pin3: [:digital, :pin3],
    pin4: [:digital, :pin4],
    a1: [:analog, :a1],
    a2: [:analog, :a2],
    adc_1: [:analog, :adc_1],
    adc_1: [:analog, :adc_2],
    pwm_1: [:hardware_pwm, :pwm_1],
    pwm_2: [:hardware_pwm, :pwm_2],
    pwm_a: [:hardware_pwm, :pwm_a],
    pwm_b: [:hardware_pwm, :pwm_b],
    softpwm_1: [:software_pwm, :softpwm_1],
    softpwm_2: [:software_pwm, :softpwm_2],
    softpwm_3: [:software_pwm, :softpwm_3],
    softpwm_a: [:software_pwm, :softpwm_a],
    softpwm_b: [:software_pwm, :softpwm_b],
    softpwm_c: [:software_pwm, :softpwm_c],
  }
  
  SupportedVersions = ['1.1', '1.0'] # in order of newness. # TODO: Add version 1.0?
  
  
  # An array of all unclaimed littlewires connected to computer via USB
  def self.all
    usb = LIBUSB::Context.new
    usb.devices.select { |device|
      device.idProduct == 0x0c9f && device.idVendor == 0x1781 && device.product == 'USBtinySPI'
    }.map { |device|
      self.new(device)
    }
  end
  
  # Frst littlewire connected to this computer via USB - good when you only have one
  def self.connect; all.first; end
  
  
  # initializes a LittleWire with a libusb device reference and some default values - does not talk to device
  def initialize devref #:nodoc:
    @device = devref
    
    @hardware_pwm_enabled = :unknown
    @hardware_pwm_prescale = :unknown
    @hardware_pwm = [0, 0]
    @software_pwm_enabled = :unknown
    @software_pwm = [0, 0, 0]
    
    # shut everything down, trying to setup littlewire in consistent initial state in case previous programs
    # messed with it's state
    self.software_pwm_enabled = false
    self.hardware_pwm_enabled = false
    self.pin_mode(pin1: :input, pin2: :input, pin3: :input, pin4: :input)
    self.digital_write(pin1: :gnd, pin2: :gnd, pin3: :gnd, pin4: :gnd)
  end
  
  # creates a lambda to close usb device when LittleWire is deallocated, without LittleWire instance closured in to it recursively
  def self.create_destructor io #:nodoc:
    lambda do
      io.close
    end
  end
  
  # Call finished when you're done with the LittleWire to release it for other programs to use. You can always claim it again
  # later by using any of the methods on this class which communicate over USB
  def finished
    if @io
      ObjectSpace.undefine_finalizer(self) # remove usb closer finalizer
      @io.close
      @io = nil
    end
  end
  
  
  # implementations of littlewire functions
  # - generic requests
  #def echo; control_transfer(function: :echo, dataIn: 8).unpack('S<*'); end # echo's usb request for testing
  #def read; control_transfer(function: :read, wIndex: 0, dataIn: 1); end
  #def write byte; control_transfer(function: :write, wIndex: 0, wValue: byte); end
  #def clear_bit bit; control_transfer(function: :clear_bit, wIndex: 0, wValue: bit); end
  #def set_bit bit; control_transfer(function: :set_bit, wIndex: 0, wValue: bit); end
  # - programming requests
  #def power_up sck_period, reset; control_transfer(function: :power_up, wIndex: sck_period, wValue: reset ? 1 : 0); end
  #def power_down; control_transfer(function: :power_down); end
  # TODO: maybe spi, poll_bytes, flash_read, flash_write, eprom_read, eeprom_write
  
  
  # returns version code number (treat it as a hex number)
  def version_hex
    @version_hex ||= control_transfer(function: :version, dataIn: 1).unpack('c').first
  end
  
  # Returns version number of firmware on LittleWire hardware
  def version
    @version ||= version_hex.to_s(16).chars.entries.join('.')
  end
  
  # get the SPI interface
  def spi
    @spi ||= SPI.new(self)
  end
  
  # get the I2C interface
  def i2c
    @i2c ||= I2C.new(self)
  end
  
  # get the 1wire interface (requires firmware 1.1 or newer
  def one_wire
    raise "You need to update your LittleWire firmware to version 1.1 to use One Wire" unless version_hex >= 0x11
    @one_wire ||= OneWire.new(self)
  end
  
  
  
  # translate calls with arduino-style lowerCamelCase method names in to ruby-style underscored_method_names
  def method_missing name, *args, &proc
    underscorized = name.to_s.gsub(/([a-z])([A-Z])/) { "#{$1}_#{$2}" }.downcase  # make underscored equivilent
    return send(underscorized, *args, &proc) if respond_to? underscorized # translate casing style if we can find an equivilent
    
    read_only = name.to_s.gsub('=', '').to_sym
    if GenericPinMap.has_key? read_only
      if name.to_s.end_with? '='
        return (self[read_only] = args.first)
      else
        return self[read_only]
      end
    end
    
    super # default behaviour
  end
  
  
  # get the value of something
  def [] name
    pin = GenericPinMap[name.to_sym]
    raise "Unknown Pin '#{name}'" unless pin
    self.send "#{pin[0]}_read", pin[1]
  end
  
  # set the value of something
  def []= name, value
    pin = GenericPinMap[name.to_sym]
    raise "Unknown Pin '#{name}'" unless pin
    self.send "#{pin[0]}_write", pin[1], value
  end
  
  protected
  # raw opened device
  def io #:nodoc:
    unless @io
      @io = @device.open
      ObjectSpace.define_finalizer(self, self.class.create_destructor(@io))
      
      # check for compatible firmware on littlewire device and warn if is unknown
      warn "Unknown littlewire.cc firmware version #{version} might cause problems" unless SupportedVersions.include? version
    end
    @io
  end
  
  # functions offered by the LittleWire
  Functions = [
    ## Generic requests
    :echo,      # echo test  0
    :read,      # read byte (wIndex:address)  1
    :write,     # write byte (wIndex:address, wValue:value)  2
    :clear_bit, # clear bit (wIndex:address, wValue:bitno)  3
    :set_bit,   # set bit (wIndex:address, wValue:bitno)  4
    ## Programming requests
    :power_up,      # apply power (wValue:SCK-period, wIndex:RESET)  5
    :power_down,    # remove power from chip  6
    :spi,           # issue SPI command (wValue:c1c0, wIndex:c3c2)  7
    :poll_bytes,    # set poll bytes for write (wValue:p1p2)  8
    :flash_read,    # read flash (wIndex:address)  9
    :flash_write,   # write flash (wIndex:address, wValue:timeout)  10
    :eeprom_read,   # read eeprom (wIndex:address)  11
    :eeprom_write,  # write eeprom (wIndex:address, wValue:timeout)  12
    ## Additional requests - ihsanKehribar
    :pin_set_input,       # 13
    :pin_set_output,      # 14
    :read_adc,            # 15
    :start_pwm,           # 16
    :update_pwm_compare,  # 17
    :pin_set_high,        # 18
    :pin_set_low,         # 19
    :pin_read,            # 20
    :single_spi,          # 21
    :change_pwm_prescale, # 22
    :setup_spi,           # 23
    :setup_i2c,           # 24
    :i2c_begin_tx,        # 25
    :i2c_add_buffer,      # 26
    :i2c_send_buffer,     # 27
    :spi_add_buffer,      # 28
    :spi_send_buffer,     # 29
    :i2c_request_from,    # 30
    :spi_update_delay,    # 31
    :stop_pwm,            # 32
    :debug_spi,           # 33
    :version,             # 34
    :analog_init,         # 35
    :reserved, :reserved, :reserved, :reserved,
    :read_buffer,         # 40
    :onewire_reset_pulse, # 41
    :onewire_send_byte,   # 42
    :onewire_read_byte,   # 43
    :i2c_init,            # 44
    :i2c_begin,           # 45
    :i2c_read,            # 46
    :init_softpwm,        # 47
    :update_softpwm,      # 48
    :i2c_update_delay,    # 49
    :onewire_read_bit,    # 50
    :onewire_write_bit,   # 51
    :pic_24f_programming, # 52 - experimental
    :pic_24f_sendsix      # 53 - experimental
    # special cases
    # pic 24f send bytes - request = 0xD*
    # i2c send multiple messages - request = 0xE*     ### experimental ###
    # spi multiple message send - request = 0xF*
  ]
  # transfer data between usb device and this program
  def control_transfer(opts = {}) #:nodoc:
    opts[:bRequest] = Functions.index(opts.delete(:function)) if opts[:function]
    io.control_transfer({
      wIndex: 0,
      wValue: 0,
      bmRequestType: usb_request_type(opts),
      timeout: 5000
    }.merge opts)
  end
  
  # calculate usb request type
  def usb_request_type opts #:nodoc:
    c = LIBUSB::Call
    value = c::RequestTypes[:REQUEST_TYPE_VENDOR] | c::RequestRecipients[:RECIPIENT_DEVICE]
    value |= c::EndpointDirections[:ENDPOINT_OUT] if opts.has_key? :dataOut
    value |= c::EndpointDirections[:ENDPOINT_IN] if opts.has_key? :dataIn
    return value
  end
  
  
  # lookup a pin name in a map and return it's raw identifier
  def get_pin map, value #:nodoc:
    value = value.to_sym if value.is_a? String
    value = map[value] if map.has_key? value
    value
  end
  
  # translate possible literal values in to a boolean true or false (meaning high or low)
  def get_boolean value #:nodoc:
    # some exceptions
    value = false if value == :low or value == 0 or value == nil or value == :off or value == :ground or value == :gnd
    !! value # double invert value in to boolean form
  end
end