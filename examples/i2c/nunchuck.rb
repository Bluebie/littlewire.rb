require '../../lib/littlewire'
require '../../lib/gadgets/nunchuck'

wire = LittleWire.connect
nunchuck = wire.nunchuck

loop do 
  puts nunchuck.sample.inspect
  sleep 0.25
end