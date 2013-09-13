class LittleWire::I2C
  def initialize wire
    @wire = wire
    @wire.control_transfer(function: :i2c_init)
  end
  
  # start an i2c message
  #
  # Arguments:
  #   address: (Integer) 7 bit numeric address
  #   direction: (Symbol) :in or :out
  #
  # Returns: true if device is active on i2c bus, false if it is unresponsive
  def start address_7bit, direction
    direction = 1 if direction == :out || direction == :output || direction == :write || direction == :send
    direction = 0 if direction != 1
    config = (address_7bit.to_i << 1) | direction
    @wire.control_transfer(function: :i2c_begin, wValue: config)
    @wire.control_transfer(function: :read_buffer, dataIn: 8).bytes.first == 0
  end
  
  # read bytes from i2c device, optionally ending with a stop when finished
  def read length, *options
    @wire.control_transfer(function: :i2c_read,
                           wValue: ((length.to_i & 0xFF) << 8) + (options.include?(:stop) ? 0 : 1),
                           wIndex: options.include?(:nack) ? 0 : 1)
    @wire.control_transfer(function: :read_buffer, dataIn: 8).bytes.first(length)
  end
  
  # write data to i2c device, optionally sending a stop when finished
  def write send_buffer, *options
    send_buffer = send_buffer.pack('C*') if send_buffer.is_a? Array
    
    byte_sets = send_buffer.bytes.each_slice(4).to_a
    byte_sets.each_with_index do |slice, index|
      stop = options.include?(:stop) && index >= byte_sets.length - 1 
      @wire.control_transfer(
        bRequest: 0xE0 | slice.length | ((options.include?(:stop) ? 1 : 0) << 3),
        wValue: ((slice[1] || 0) << 8) + (slice[0] || 0),
        wIndex: ((slice[3] || 0) << 8) + (slice[2] || 0)
      )
    end
  end
  
  # simplified syntax to send a message to an address
  def send address, bytes, options = [:stop]
    raise "I2C Device #{address} Unresponsive" unless start(address, :out)
    write(bytes, options)
  end
  
  # simplified syntax to read value of a register
  def request address, bytesize = 6, options = [:stop, :nack]
    raise "I2C Device #{address} Unresponsive" unless start(address, :in)
    read bytesize, options
  end
  
  # send a stop without sending any bytes (idk if this is even a thing people do?)
  def stop
    write [], true
  end
  
  # set the update delay of LittleWire's i2c module in microseconds
  def delay= update_delay
    @wire.control_transfer(function: :i2c_update_delay, wValue: update_delay.to_i)
  end
  
  # Search all 128 possible i2c device addresses, starting a message to each and
  # testing if devices respond at each location.
  #
  # Returns: Array of Integer addresses
  def search
    128.times.select do |address|
      address_responds? address
    end
  end
  
  # Test if an i2c address responds to requests - e.g. is it plugged in to the network?
  #
  # Arguments:
  #   - address - an integer between 0 and 127 inclusive
  # Returns: true or false
  def address_responds? address
    raise "Address must be an Integer" unless address.is_a? Integer
    raise "Address too high. Max is 127" if address > 127
    raise "Address too low. Needs to be at least 0" if address < 0
    start(address, :write)
  end
end
