# Interface to LittleWire 1.1's software pwm feature
module LittleWire::SoftwarePWM
  # Has the software pwm module been enabled?
  attr_reader :software_pwm_enabled
  
  # Set if the software pwm module is enabled or inactive
  def software_pwm_enabled= value
    value = !! value # booleanify it
    if @software_pwm_enabled != value
      require_software_pwm_available
      control_transfer(function: :init_softpwm, wValue: value ? 1 : 0)
      @software_pwm_enabled = value
    end
  end
  
  # An array of current software pwm values
  def software_pwm; @software_pwm.dup; end
  
  # Set software pwm to the values of an array - values must be a number between 0 and 255 inclusive
  def software_pwm= values
    require_software_pwm_available
    self.software_pwm_enabled = true
    
    3.times do |idx|
      @software_pwm[idx] = values[idx].to_i % 256
    end
    
    control_transfer(function: :update_softpwm, wValue: @software_pwm[1] << 8 | @software_pwm[0], wIndex: @software_pwm[2])
  end
  
  # Get the value of a single software pwm channel
  def software_pwm_read channel
    @software_pwm[get_pin(LittleWire::SoftwarePWMPinMap, channel)]
  end
  
  # Set the value of a single software pwm channel - value must be a number between 0 and 255 inclusive
  def software_pwm_write *args
    if args.first.is_a? Hash
      args.first.each do |pin, value|
        self.software_pwm_write(pin, value)
      end
    else
      raise "Invalid Arguments" unless args.length == 2
      channel, value = args
      state = self.software_pwm
      state[get_pin(LittleWire::SoftwarePWMPinMap, channel)] = value
      self.software_pwm = state
    end
  end
  
  def is_software_pwm_available?
    version_hex >= 0x11
  end
  
  private
  def require_software_pwm_available
    raise "Software PWM not available in version #{self.version} firmware" unless is_software_pwm_available?
  end
end