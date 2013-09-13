require '../../lib/littlewire'

# Make a class which represents a digispark with the digistump eeprom shield attached
# with LittleWire installed
class DigisparkEEPROM
  def initialize wire = LittleWire.connect, address = 0x50
    raise "EEPROM device not responding" unless wire.i2c.address_responds? address
    
    @wire = wire
    @device = address
    
    @wire.i2c.delay = 10
  end
  
  def read address
    @wire.i2c.transmit @device, [(address >> 8) & 0xFF, address & 0xFF]
    @wire.i2c.request(@device, 1)
  end
  
  def write address, data
    @wire.i2c.transmit @device, [address >> 8, address & 0xFF, data]
    sleep 0.01 # time to write data
  end
end

eep = DigisparkEEPROM.new

number = rand(127)
puts "Random number is #{number}"
puts "Writing to eeprom at address 0"
eep.write 0, number
puts "Reading back..."
puts eep.read(0)