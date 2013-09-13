class LittleWire
  # get Wii Nunchuck interface
  def nunchuck
    @nunchuck ||= LittleWire::Nunchuck.new self
  end
end

class LittleWire::Nunchuck
  BusAddress = 82 # Address of Nunchuck on i2c bus
  
  def initialize wire
    @wire = wire
    
    # config i2c to reliably talk with nunchuck devices
    #i2c.delay = 10 # this can probably be quite a bit lower. Maybe even 0
    
    # test if nunchuck is responsive
    raise "Nunchuck is unresponsive" unless i2c.address_responds? BusAddress
    
    sleep 0.1
    # initialize the nunchuck
    # i2c.send BusAddress, [0x55, 0xF0]
    i2c.send BusAddress, [64, 0]
    sleep 0.1
    # i2c.send BusAddress, [0x00, 0xFB]
  end
  
  def sample
    # read six bytes from read address 0xa5
    data = i2c.request(BusAddress, 6)
    puts data.inspect
    data.map! { |x| (0x17 ^ x) + 0x17 } # "decrypt" data
    sleep 0.1
    i2c.send BusAddress, [0]
    sleep 0.1
    
    LittleWire::Nunchuck::NunchuckFrame.new(data)
  end
  
  private
  def i2c
    @i2c ||= @wire.i2c
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
