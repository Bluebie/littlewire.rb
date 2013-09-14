class LittleWire::I2C
  def initialize wire
    @wire = wire
    raise "i2c support requires littlewire firmware 1.2 or newer. Please update to firmware #{LittleWire::SupportedVersions.first} with the `littlewire.rb install #{LittleWire::SupportedVersions.first}` command!" if wire.version_hex < 0x12
    warn "i2c delay support is buggy in firmware 1.2. Please update firmware to at least 1.3" if wire.version_hex == 0x12
    @wire.control_transfer(function: :i2c_init, dataIn:8)
  end
  
  # start an i2c message
  #
  # Arguments:
  #   address: (Integer) 7 bit numeric address
  #   direction: (Symbol) :in or :out
  #
  # Returns: true if device is active on i2c bus, false if it is unresponsive
  def start address_7bit, direction
    raise "Address is too high" if address_7bit > 127
    raise "Address is too low" if address_7bit < 0
    
    direction = :write if direction == :out || direction == :output || direction == :send
    config = (address_7bit.to_i << 1) | ((direction == :write) ? 0 : 1)
    
    @wire.control_transfer(function: :i2c_begin, wValue: config, dataIn: 8)
    @wire.control_transfer(function: :read_buffer, dataIn: 8).bytes.first == 0
  end
  
  # read bytes from i2c device, optionally ending with a stop when finished
  def read length, stop_at_end = true
    @wire.control_transfer(function: :i2c_read, dataIn: 8,
                           wValue: ((length.to_i & 0xFF) << 8) + (stop_at_end ? 1 : 0),
                           wIndex: stop_at_end ? 1 : 0)
    @wire.control_transfer(function: :read_buffer, dataIn: 8).bytes.first(length)
  end
  
  # write data to i2c device, optionally sending a stop when finished
  def write send_buffer, stop_at_end = true
    #send_buffer = send_buffer.pack('C*') if send_buffer.is_a? Array
    send_buffer = send_buffer.bytes if send_buffer.is_a? String
    
    #byte_sets = send_buffer.each_slice(4).to_a
    #byte_sets.each_with_index.map do |slice, index|
    #  do_stop = stop_at_end && index >= byte_sets.length - 1 
    slice = send_buffer
    do_stop = stop_at_end
      @wire.control_transfer(
        bRequest: 0xE0 + slice.length + ((do_stop ? 1 : 0) << 3),
        wValue: ((slice[1] || 0) << 8) + (slice[0] || 0),
        wIndex: ((slice[3] || 0) << 8) + (slice[2] || 0),
        dataIn: 8
      )
    #end
  end
  
  # simplified syntax to send a message to an address
  def transmit address, *args
    raise "I2C Device #{address} Unresponsive" unless start(address, :write)
    write(*args)
  end
  
  # simplified syntax to read value of a register
  def request address, *args
    raise "I2C Device #{address} Unresponsive" unless start(address, :read)
    read *args
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
