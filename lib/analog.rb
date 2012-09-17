module LittleWire::Analog
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
                       wValue: get_pin(AnalogPinMap, input_name),
                       dataIn: 2).unpack('S<').first / 1024.0
  end
  
  # Get the current temperature inside the LittleWire device's microcontroller. At a courseness of about 1.1°C increments
  # and quite a lot of noise in the measurements, some averaging is required. Rather neatly, because of the noise in each
  # sample, when averaged you get higher than 1.1°C resolution.
  #
  # This method returns a value around 280.0 - you'll need to calibrate it yourself by simple subtraction. You can calibrate
  # it even more accurately by linearly mapping it to two known temperature points. Each LittleWire is a bit different so some
  # calibration is necessary (unless you just want to take relative measurements).
  def temperature
    (analog_read(:temperature, :internal_reference_1_1) * 1024.0) / 1.12
  end
  
end