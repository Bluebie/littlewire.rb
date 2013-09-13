class LittleWire
  # get Wii Nunchuck interface
  def nunchuck
    @nunchuck ||= LittleWire::Nunchuck.new self
  end
end

class LittleWire::Nunchuck
  BusAddress = 0xA4 # Address of Nunchuck on i2c bus
  BusReadAddress = 0xA5 # Address to read from
  
  def initialize wire
    @wire = wire
    
    # initialize the nunchuck
    i2c.delay = 0
    #i2c.send BusAddress, [0x55, 0xF0]
    #i2c.send BusAddress, [0x00, 0xFB]
    # i2c.send BusAddress, [0xF0, 0x55]
    # i2c.send BusAddress, [0xFB, 0x00]
    i2c.send BusAddress, [0x40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  end
  
  def sample
    # set read pointer to 0
    i2c.send BusAddress, [0] 
    # read six bytes from read address 0xa5
    data = i2c.request(BusReadAddress, 6)
    puts data.inspect
    
    LittleWire::Nunchuck::NunchuckFrame.new(data)
  end
  
  private
  def i2c
    @i2c ||= @wire.i2c
  end
  
  def ack
    i2c.start 0x52, :out
    i2c.write [0x00], true
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
    def to_a; [@x,@y,@z]; end
    def to_h; {x: @x, y: @y, z: @z}; end
    def to_hash; to_h; end
    def inspect; "<Vector3D:" + to_h.delete_if { |k,v| v == nil }.inspect + ">"; end
  end
  
  class Buttons
    def initialize c,z
      @c,@z = c,z
    end
    attr_accessor :c, :z
    def inspect; "<Buttons:#{'C' if @c}#{'Z' if @z}>"; end
  end
end
