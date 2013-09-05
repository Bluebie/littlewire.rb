require 'test/unit'
require '../lib/littlewire'

# unit tests for the easy stuff - don't need anything wired to littlewire to run test
class TestSimpleIO < Test::Unit::TestCase
  def test_io
    wire = LittleWire.connect
    assert_not_nil(wire, "Find and connect to a LittleWire device") # make sure found a wire
    
    wire.pinMode(ds1: :input)
    wire.digital_write(ds1: :high)
    assert(wire.digital_read(:ds1) == true, "Digital Read pulled high pin is high") # check pullup worked
    
    # now check analog inputs are functioning
    wire.pinMode(ds2: :input)
    wire.digitalWrite(ds2: :high)
    
    analog = wire.analog_read(:ds2)
    puts "Pin raised to #{analog.inspect}"
    assert(analog > 0.90, "pullup raised ADC input quite high")
    
    assert(wire.digital_read([:ds0, :ds1]).is_a?(Array), "digital_read array of pins returns array")
    assert(!wire.digital_read(:ds5).is_a?(Array), "digital_read a single pin returns a direct boolean value")
    
    10.times { wire.temperature } # make sure everything is stable
    temp = wire.temperature # check temperature sensor mode is working
    puts "Uncalibrated Temperature value is #{temp.inspect}"
    assert(temp != nil, "temperature returns non-nil value")
    assert(temp > 0.0, "temperature didn't return 0")
    
    assert_nothing_raised do
      wire.digital_write(ds0: true) # these three mean the same thing
      wire.digital_write(ds0: :high)
      wire.digital_write(pin4: true)
      
      wire.pin_mode(:ds0, :input) # and these are the same
      wire.pin_mode(ds0: :input)
      
      wire.pinMode(ds0: :output)
      wire.digitalWrite(ds0: :high) # check camelcase syntax
    end
  end
end