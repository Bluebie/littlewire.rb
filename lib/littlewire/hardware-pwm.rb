module LittleWire::HardwarePWM
  attr_reader :hardware_pwm_enabled # initially :unknown, then a boolean
  
  # Set hardware pwm as enabled or disabled - hardware pwm is automatically enabled when you start using it
  # but must be disabled before using these pins again for other purposes
  def hardware_pwm_enabled= value
    return if @hardware_pwm_enabled == value
    @hardware_pwm_enabled = !!value
    control_transfer(function: value ? :start_pwm : :stop_pwm)
  end
  
  # Get an array of the current values in the Hardware PWM module
  def hardware_pwm; @hardware_pwm.dup; end
  
  # Set Hardware PWM to an array of new values - array must be two items long
  def hardware_pwm= values
    self.hardware_pwm_enabled = true
    @hardware_pwm[0] = values[0].to_i % 256
    @hardware_pwm[1] = values[1].to_i % 256
    control_transfer(function: :update_pwm_compare, wValue: @hardware_pwm[0].to_i, wIndex: @hardware_pwm[1].to_i)
  end
  
  # Get the current value of a Hardware PWM channel (stored in littlewire.rb library - not requested from device)
  def hardware_pwm_read channel; hardware_pwm[get_pin(LittleWire::HardwarePWMPinMap, channel)]; end
  
  # Set an individual Hardware PWM channel to a new value in the range of 0-255
  def hardware_pwm_write channel, value
    updated = self.hardware_pwm
    updated[get_pin(LittleWire::HardwarePWMPinMap, channel)] = value
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

end