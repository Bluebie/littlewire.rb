# A little blinky test to show how to make stuff happen with a littlewire in ruby!
#
# To get started, plug an LED in to the ISP cable between ground and Pin 4 (they're next to each other) via a resistor (resistor not optional)
require '../lib/littlewire.rb'

wire = LittleWire.connect

FPS = 60 # update 60 times per second
fader = 0.0 # our current position

loop do
  value = (Math.sin(fader) + 1.0) * 127.0 # calculate an ideal brightness
  
  ## Some equivilent ways of expressing this idea:
  # wire.software_pwm_write(:softpwm_a, value)
  # wire[:softpwm_a] = value
  # wire[:softpwm_1] = value
  wire.softpwm_a = value
  
  fader += 0.025
  sleep 1.0 / FPS
end
