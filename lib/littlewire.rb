# A little library for a little wire, by Bluebie
# Provides an arduino or wiring style interface to the LittleWire device's IO features
# and provides a nicer invented ruby-style interface also.
require 'libusb'

# LittleWire class represents LittleWire's connected to your computer via USB
# 
# Most of the time you'll only have one LittleWire - in this case, use LittleWire.connect to get
# ahold of your wire. If you have more than one, you can use LittleWire.all to fetch an array of them
class LittleWire
  # pin name to numeric internal code maps
  DigitalPinMap = { # maps common names to bit positions in PORTB
    pin1: 1, d1: 1, miso:  1, pwm_b: 1,
    pin2: 2, d2: 2, sck:   2,
    pin3: 5, d3: 5, reset: 5,
    pin4: 0, d4: 0, mosi:  0, pwm_a: 0 }
  AnalogPinMap = { # maps common names to switch index in littlewire firmware
    a1: 0, adc_1: 0, reset: 0, pin3: 0, d3: 0,
    a2: 1, adc_2: 1, sck:   1, pin2: 1, d2: 1,
    temperature: 2, temp: 2 }
  HardwarePWMPinMap = { # maps common pin names to @hardware_pwm array index
    pwm_a: 0, d1: 0, pin4: 0, mosi: 0,
    pwm_b: 1, d2: 1, pin1: 1, miso: 1 }
  SoftwarePWMPinMap = {
    softpwm_1: 0, softpwm_a: 0,
    softpwm_2: 1, softpwm_b: 1,
    softpwm_3: 2, softpwm_c: 2 }
  GenericPinMap = { # generic pinmap used by [] and []= methods to refer to anything
    d1: [:digital, :pin1],
    d2: [:digital, :pin2],
    d3: [:digital, :pin3],
    d4: [:digital, :pin4],
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
  
  VersionCodes = {0x11 => '1.1', 0x10 => '1.0'} # translate version codes in to friendly strings
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
  def echo; control_transfer(function: :echo, dataIn: 8).unpack('S<*'); end # echo's usb request for testing
  def read; control_transfer(function: :read, wIndex: 0, dataIn: 1); end
  def write byte; control_transfer(function: :write, wIndex: 0, wValue: byte); end
  def clear_bit bit; control_transfer(function: :clear_bit, wIndex: 0, wValue: bit); end
  def set_bit bit; control_transfer(function: :set_bit, wIndex: 0, wValue: bit); end
  # - programming requests
  #def power_up sck_period, reset; control_transfer(function: :power_up, wIndex: sck_period, wValue: reset ? 1 : 0); end
  #def power_down; control_transfer(function: :power_down); end
  # TODO: spi, poll_bytes, flash_read, flash_write, eprom_read, eeprom_write
  
  PinModes = {input: :pin_set_input, output: :pin_set_output} #:nodoc:
  # Set pins to either of :output or :input modes
  # In :input mode:
  #       pins digitally written to `false` are unconnected to any voltage
  #       pins digitally written to `true` are connected via an internal 20kohm resistor to 5 volts (pullup mode)
  # In :output mode:
  #       pins digitally written to `false` are connected directly to ground
  #       pins digitally written to `true` are connected directly to 5 volts
  #
  # Always be careful not to create short circuits when setting pins to output - your LittleWire could break under the stress.
  #
  # pin_mode can be called as pin_mode(:pin_name, :output) or as pin_mode(pin_name: :output, other_pin: :input)
  def pin_mode *args
    if args.length == 1 and args.first.is_a? Hash
      hash = args.first
      hash.each do |key, value|
        self.pin_mode(key, value)
      end
    elsif args.length == 2 and (args[0].is_a?(Symbol) or args[0].is_a?(Integer))
      pin, mode = args
      modes = {input: :pin_set_input, output: :pin_set_output}
      raise "Unknown mode #{mode}" unless modes[mode]
      control_transfer(function: modes[mode], wValue: map_resolve(DigitalPinMap, pin))
    else
      raise "requires one or two arguments - ({hash of pins and modes}) or (pin, mode)"
    end
  end
  
  # reads the digital voltage level of a specified pin and returns true if it is roughly closer to 5v than 0v, or false otherwise
  def digital_read pin
    control_transfer(function: :pin_read, dataIn: 1, wValue: map_resolve(DigitalPinMap, pin)).bytes.first != 0
  end
  
  # Set a pin. Behaviour is dependant on pin's mode:
  #
  # Pin is an :input:
  #     `true` connects pin to 5v via an internal 20kohm resistor (pullup mode)
  #     `false` disconnects pin from any voltage, allowing it to float freely
  # Pin is an :output:
  #     `true` connects pin directly to 5v
  #     `false` connects pin directly to ground (0v)
  #
  # Be careful not to create short circuits on pins that are in :output mode, as these can harm your littlewire.
  # Pullup mode is useful for creating buttons.
  def digital_write pin, value
    control_transfer(function: value ? :pin_set_high : :pin_set_low, wValue: map_resolve(DigitalPinMap, pin))
  end
  
  # Read the current value of an analog input
  # Valid inputs are 
  AnalogReferences = [:vcc, :internal_reference_1_1, :internal_reference_2_56]
  def analog_read input_name, voltage_reference = :vcc
    voltage_reference = AnalogReferences.index(voltage_reference) if AnalogReferences.include? voltage_reference
    scaling_setting = 0x07
    
    if @analog_reference != voltage_reference
      @analog_reference = voltage_reference
      # This reset step is to work around a bug in firmware 1.1 - hopefully it can be disabled in future releases
      control_transfer(function: :analog_init, wValue: scaling_setting) # reset analog reference setting
      # set new reference voltage
      control_transfer(function: :analog_init, wValue: scaling_setting | voltage_reference << 8)
    end
    
    control_transfer(function: :read_adc,
                       wValue: map_resolve(AnalogPinMap, input_name),
                       dataIn: 2).unpack('S<').first / 1024.0
  end
  
  # Read the current temperature inside the LittleWire's chip, at roughly 1°C increments
  # temperature must be calibrated by user through simple subtraction. The data is also pretty noisy and requires some
  # averaging for most uses
  def temperature
    (analog_read(:temperature, :internal_reference_1_1) * 1024.0) / 1.12
  end
  
  # Set hardware pwm as enabled or disabled - hardware pwm is automatically enabled when you start using it
  attr_reader :hardware_pwm_enabled
  def hardware_pwm_enabled= value
    return if @hardware_pwm_enabled == value
    @hardware_pwm_enabled = !!value
    control_transfer(function: value ? :start_pwm : :stop_pwm)
  end
  
  # Array of current hardware pwm values
  def hardware_pwm; @hardware_pwm.dup; end
  
  # Set hardware pwm to an array of new values - array must be two items long
  def hardware_pwm= values
    self.hardware_pwm_enabled = true
    @hardware_pwm[0] = values[0].to_i % 256
    @hardware_pwm[1] = values[1].to_i % 256
    control_transfer(function: :update_pwm_compare, wValue: @hardware_pwm[0].to_i, wIndex: @hardware_pwm[1].to_i)
  end
  
  # Get the value of an individual hardware pwm channel
  def hardware_pwm_read channel; hardware_pwm[map_resolve(HardwarePWMPinMap, channel)]; end
  
  # Set the value of an individual hardware pwm channel to a number between 0 and 255 inclusive
  def hardware_pwm_write channel, value
    updated = self.hardware_pwm
    updated[map_resolve(HardwarePWMPinMap, channel)] = value
    self.hardware_pwm = updated
  end
  
  
  PWMPrescaleSettings = [1, 8, 64, 256, 1024] # :nodoc:
  # Set division of the Hardware PWM Prescaler - default 1024. This setting controls how quickly LittleWire's PWM channels oscillate
  # between their 'high' and 'low' state. Lower prescaler values are often nicer for lighting, while higher values can be better for
  # motor speed control and 1024 is required for servo position control
  #     1024: roughly 63hz
  #     256: roughly 252hz
  #     64: roughly 1khz
  #     8: roughly 8khz
  #     1: roughly 64khz
  #
  # No other values are accepted
  def hardware_pwm_prescale= division
    raise "Unsupported Hardware PWM Prescale value, must be #{PWMPrescaleSettings.inspect}" unless PWMPrescaleSettings.include? division
    if @hardware_pwm_prescale != division
      @hardware_pwm_prescale = division
      control_transfer(function: :change_pwm_prescale, wValue: PWMPrescaleSettings.index(division))
    end
  end
  
  ############# Servos ############
  
  # Get the current andle of a servo connected to a hardware pwm channel as an angle between roughly -90° and +90°
  def servo_read hardware_pwm_channel
    value = hardware_pwm_read(hardware_pwm_channel)
    90 - ((value - 13).to_f * (180.0 / 23.0))
  end
  
  # Set a servo connected to a hardware pwm channel to an angle between -90° and +90° inclusive
  def servo_write hardware_pwm_channel, angle
    self.hardware_pwm_prescale = 1024 # make sure our PWM is running at the correct frequency
    
    value = ((angle + 90.0) / (180.0 / 23.0)).round + 13
    
    hardware_pwm_write(hardware_pwm_channel, value)
  end
  
  ############# Software PWM ##############
  
  # Has the software pwm module been enabled?
  attr_reader :software_pwm_enabled
  
  # Set if the software pwm module is enabled or inactive
  def software_pwm_enabled= value
    value = !! value # booleanify it
    if @software_pwm_enabled != value
      control_transfer(function: :init_softpwm, wValue: value ? 1 : 0)
      @software_pwm_enabled = value
    end
  end
  
  # An array of current software pwm values
  def software_pwm; @software_pwm.dup; end
  
  # Set software pwm to the values of an array - values must be a number between 0 and 255 inclusive
  def software_pwm= values
    self.software_pwm_enabled = true
    
    3.times do |idx|
      @software_pwm[idx] = values[idx].to_i % 256
    end
    
    control_transfer(function: :update_softpwm, wValue: @software_pwm[1] << 8 | @software_pwm[0], wIndex: @software_pwm[2])
  end
  
  # Get the value of a single software pwm channel
  def software_pwm_read channel; @software_pwm[map_resolve(SoftwarePWMPinMap, channel)]; end
  
  # Set the value of a single software pwm channel - value must be a number between 0 and 255 inclusive
  def software_pwm_write channel, value
    state = self.software_pwm
    state[map_resolve(SoftwarePWMPinMap, channel)] = value
    self.software_pwm = state
  end
  
  
  
  # Returns version number of firmware on LittleWire hardware
  def version
    v = control_transfer(function: :version, dataIn: 1).unpack('c').first
    v = VersionCodes[v] if VersionCodes.has_key? v
    v = "0x#{v.to_s(16)}" if v.is_a? Integer
    v
  end
  
  
  
  
  
  # translate calls with arduino-style lowerCamelCase method names in to ruby-style underscored_method_names
  def method_missing name, *args, &proc
    underscorized = name.to_s.gsub(/([a-z])([A-Z])/) { "#{$1}_#{$2}" }.downcase  # make underscored equivilent
    return send(underscorized, *args, &proc) if respond_to? underscorized # translate casing style if we can find an equivilent
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
      ver = self.version
      warn "Unknown littlewire.cc firmware version #{ver.to_s(16)} might cause problems" unless SupportedVersions.include? ver
      warn "LittleWire is running old firmware version #{ver} - some features might not work" if ver != SupportedVersions.first
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
  def control_transfer(opts = {}) #:nodoc:
    opts[:bRequest] = Functions.index(opts.delete(:function)) if opts[:function]
    io.control_transfer({
      wIndex: 0,
      wValue: 0,
      bmRequestType: usb_request_type(opts),
      timeout: 5000
    }.merge opts)
  end
  
  def usb_request_type opts #:nodoc:
    c = LIBUSB::Call
    value = c::RequestTypes[:REQUEST_TYPE_VENDOR] | c::RequestRecipients[:RECIPIENT_DEVICE]
    value |= c::EndpointDirections[:ENDPOINT_OUT] if opts.has_key? :dataOut
    value |= c::EndpointDirections[:ENDPOINT_IN] if opts.has_key? :dataIn
    return value
  end
  
  
  # lookup a pin name in a map and return it's raw identifier
  def map_resolve map, value #:nodoc:
    value = value.to_sym if value.is_a? String
    value = map[value] if map.has_key? value
    value
  end
end