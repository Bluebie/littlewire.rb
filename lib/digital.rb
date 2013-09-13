module LittleWire::Digital
  EnableBulkWrite = false # this thing seems to not work good - not ready for real world use
  # these firmwares have a default state specified, enabling bulk writing
  BulkWriteDefaultStates = { '1.1' => 0b00001000 } # D- usb bit is high, others are low
  BulkWriteBitmask =       { '1.1' => 0b00100111 }
  
  # Write one or more digital values to device pins
  # 
  # A simple invokation is `my_wire.digital_write(:pin1, true)` setting pin1 to a
  # high logic level. :high and :low can be substituted for true and false, as can
  # :on and :off, :vcc and :gnd or :ground
  #
  # `digital_write` can also be called with a hash: `my_wire.digital_write(:pin1 => true)`
  # allowing multiple pins to be set at once. A system for updating all pins simultaniously is being
  # worked on, but is not yet stable, so for now digital_write uses a request for each pin.
  #
  # Automatically disables PWM and Servo features if you try to write to a pin used by those modules
  def digital_write *args
    if args.length > 1
      self.digital_write({args[0] => args[1]})
    else
      raise "Incorrect Arguments" unless args.first.respond_to? :to_hash
      hash = args.first.to_hash
      
      #self.hardware_pwm_enabled = false if hash.keys.any? { |pin| LittleWire::HardwarePWMPinMap.has_key? pin }
      #self.software_pwm_enabled = false if hash.keys.any? { |pin| LittleWire::SoftwarePWMPinMap.has_key? pin }
      
      if use_experimental_bulk_write?
        # could cause problems - must do tests when deciding if to enable this or not
        @bulk_write_bitmap ||= 0
        
        hash.each do |pin, state|
          if get_boolean(state)
            @bulk_write_bitmap |= 1 << get_pin(LittleWire::DigitalPinMap, pin)
          else
            @bulk_write_bitmap &= ~(1 << get_pin(LittleWire::DigitalPinMap, pin))
          end
        end
        value = (@bulk_write_bitmap & BulkWriteBitmask[self.version]) | BulkWriteDefaultStates[self.version]
        control_transfer(function: :write, wValue: value)
      else
        hash.each do |pin, state|
          control_transfer(
            function: get_boolean(state) ? :pin_set_high : :pin_set_low,
            wValue: get_pin(LittleWire::DigitalPinMap, pin)
          )
        end
      end
    end
  end
  
  # Read one or more digital values from device pins
  #
  # The simplest invocation is `my_wire.digital_read(:pin1)`, returning a true or false
  # where true is a high (positive) voltage and false is a lower (near ground) voltage
  #
  # A more advanced invokation is passing several pins as arguments or an array of pins
  # `sensor_a, sensor_b = my_wire.digital_read(:pin1, :pin2)` which reads both pins at
  # the exact same instant in just one USB request, returning an array of the results
  #
  # digital_read works best when the pin is in :input mode. See also #pin_mode
  def digital_read *args
    raise "Incorrect Arguments" if args.length < 1
    pins = args.flatten
    port = control_transfer(function: :read, dataIn: 1).unpack('c').first
    mapped = pins.map do |pin|
      pin = get_pin(LittleWire::DigitalPinMap, pin)
      ((port >> pin) & 1) == 1 # discover if pin is high or low
    end
    
    if args.length == 1 and (args.first.is_a?(Symbol) or args.first.is_a?(Integer))
      mapped.first
    else
      mapped
    end
  end
  
  # Set the mode of one or more device pins
  #
  # A simple form is `my_wire.pin_mode(:pin1, :input)` setting pin1 to input mode.
  # Multiple pins can be set using `my_wire.pin_mode(:pin1 => :input, :pin2 => :output)`
  # 
  # :input mode leaves the pin disconnected if `digital_write`n to false, or connected
  # via a 20kohm resistor to 5 volts if `digital_write` to true.
  #
  # :output mode connects the pin directly to 5 volts when `digital_write`n to true
  # and connects it to ground when digitally written to false. Be careful not to create
  # short circuits as these may damage your LittleWire.
  def pin_mode *args
    if args.length == 2
      self.pin_mode( args[0] => args[1] )
    else
      raise if args.length != 1 or !args.first.is_a?(Hash)
      
      modes = {
        :input => :pin_set_input, :in => :pin_set_input,
        :output => :pin_set_output, :out => :pin_set_output
      }
      args.first.each do |pin, mode|
        raise "Unknown mode #{mode.inspect}" unless modes[mode.to_sym]
        control_transfer(function: modes[mode.to_sym], wValue: get_pin(LittleWire::DigitalPinMap, pin))
      end
    end
  end
  
  private
  def use_experimental_bulk_write?
    EnableBulkWrite and BulkWriteDefaultStates.include?(self.version.to_s)
  end
end