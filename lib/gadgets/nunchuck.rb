class LittleWire
  # get Wii Nunchuck interface
  def nunchuck
    @nunchuck ||= LittleWire::Nunchuck.new self
  end
end

class LittleWire::Nunchuck
  BusAddress = 82 # Address of Nunchuck on i2c bus
  
  def initialize wire, interval = 0
    @wire = wire
    
    raise "Nunchuck requires LittleWire firmware 1.3 or newer" unless wire.version_hex >= 0x13
    
    # config i2c to reliably talk with nunchuck devices
    i2c.delay = interval # The fastest option of 0 seems to work. Neat!
    
    # initialize the nunchuck
    set_register 0xf0, 0x55
    set_register 0xfb, 0x00
    sample # do a sample, to get the ball rolling
  end
  
  def sample
    # tell device to gather new sensor data
    i2c.transmit BusAddress, [0]
    # load sample in to PC
    data = i2c.request(BusAddress, 6)
    
    LittleWire::Nunchuck::NunchuckFrame.new(data)
  end
  
  private
  def i2c
    @i2c ||= @wire.i2c
  end
  
  def set_register register, value
    i2c.transmit BusAddress, [register, value]
    sleep(0.01)
  end
end

class LittleWire::Nunchuck::NunchuckFrame
  def initialize data
    @data = data
    @joystick = Vector3D.new((data[0] / 127.5) - 1.0, (data[1] / 127.5) - 1.0)
    @buttons = Buttons.new(((data[5] >> 1) & 1) == 0, (data[5] & 1) == 0)
    
    #calculate accelerometer values
    @accelerometer = Vector3D.new(data[2] << 2, data[3] << 2, data[4] << 2)
    @accelerometer.x |= (data[5] >> 2) & 0b11
    @accelerometer.y |= (data[5] >> 4) & 0b11
    @accelerometer.z |= (data[5] >> 6) & 0b11
    
    @accelerometer.x = (@accelerometer.x / 511.5) - 1.0
    @accelerometer.y = (@accelerometer.y / 511.5) - 1.0
    @accelerometer.z = (@accelerometer.z / 511.5) - 1.0
  end
  
  attr_reader :joystick, :accelerometer, :buttons
  
  def inspect
    "<Nunchuck:#{buttons.inspect}:#{accelerometer.inspect}:#{joystick.inspect}"
  end
  
  class Vector3D
    def initialize x=nil, y=nil, z=nil
      @x,@y,@z = x,y,z
    end
    
    attr_accessor :x,:y,:z
    def to_a; [@x,@y,@z].compact; end
    def to_h; {x: @x, y: @y, z: @z}; end
    def to_hash; to_h; end
    def inspect
      precision = 2
      pretty = lambda { |n| (n >= 0 ? '+' : '-') + n.abs.round(precision).to_s.ljust(precision + 2, '0') }
      numbers = to_a.map { |n| pretty[n] }
      "<Coords:" + numbers.join(',') + ">"
    end
  end
  
  class Buttons
    def initialize c,z
      @c,@z = c,z
    end
    attr_accessor :c, :z
    
    # is button down?
    def down? button
      instance_variable_get("@#{button.to_s.downcase}")
    end
    
    def up? button
      not down? button
    end
    
    def inspect; "<Buttons:#{'C' if @c}#{'Z' if @z}>"; end
  end
end
