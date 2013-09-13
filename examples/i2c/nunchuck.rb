require '../../lib/littlewire'
require '../../lib/gadgets/nunchuck'

wire = LittleWire.connect

loop do 
  puts wire.nunchuck.sample.inspect
  sleep 0.25
end