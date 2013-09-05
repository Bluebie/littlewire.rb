# Read the state of a button connecting between pin 0 and ground on a digispark
require '../lib/littlewire'
wire = LittleWire.connect

wire.pin_mode ds1: :input
wire.digital_write ds1: true
puts "Pin 1 is " + wire.digital_read(:ds1).inspect
