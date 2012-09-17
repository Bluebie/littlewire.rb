module LittleWire::Servo
  # Get the current andle of a servo connected to a hardware pwm channel as an angle between roughly -90° and +90°
  def servo_read hardware_pwm_channel
    value = hardware_pwm_read(hardware_pwm_channel)
    90 - ((value - 13).to_f * (180.0 / 23.0))
  end
  
  # Set a servo connected to a hardware pwm channel to an angle between -90° and +90° inclusive
  # Note that setting a servo's position automatically enables Hardware PWM - disable hardware pwm when you're done
  # if you want to use these pins for something else
  def servo_write hardware_pwm_channel, angle
    self.hardware_pwm_prescale = 1024 # make sure our PWM is running at the correct frequency
    
    value = ((angle + 90.0) / (180.0 / 23.0)).round + 13
    
    hardware_pwm_write(hardware_pwm_channel, value)
  end
end