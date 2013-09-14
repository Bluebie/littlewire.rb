# This little example shows the nunchuck gadget extension
# The Nunchuck gadget lets you easily connect with Nintendo Wii-compatible
# 'Nunchuck' devices using the I2C feature of the LittleWire device.
require 'littlewire'
require 'littlewire/gadgets/nunchuck'

wire = LittleWire.connect
wire.pin_mode :ds5, :output
wire.digital_write :ds5, :low

car = 0.0
wall = 0.0
wall_width = 16
constraint = 20.0

puts DATA.read
puts ''
puts "Point your nunchuck at the screen, and press C button to start your engines!"
sleep 0.1 until wire.nunchuck.sample.buttons.c

seconds = 0.0
seconds_since_gearshift = 0.0
last_full_second = 0
step = 0.1

GearshiftInterval = 10.0

loop do
  controller = wire.nunchuck.sample
  car += controller.accelerometer.x * 2.0
  
  wall += rand(3) - 1
  wall = -20.0 if wall < -constraint
  wall = +20.0 if wall > +constraint
  
  real_wall = wall + constraint * 2 + 1
  real_car = car + constraint * 2 + 1
  
  string = " " * 80
  string[real_wall - wall_width / 2] = '|'
  string[real_wall + wall_width / 2] = '|'
  string[real_car] = '5'
  
  if seconds > last_full_second + 5
    string[0...10] = seconds.round.to_s.ljust(10, ' ')
    last_full_second = seconds.round
  end
  puts string
  
  raise "Crashed your car!" if real_car < real_wall - (wall_width / 2)
  raise "Crashed your car!" if real_car > real_wall + (wall_width / 2)
  
  sleep step
  seconds += step
  seconds_since_gearshift += step
  if seconds_since_gearshift > GearshiftInterval
    step *= 0.8
    seconds_since_gearshift = 0.0
  end
end

__END__
                    ______   __  __    ____     ____     ____
                   /_  __/  / / / /   / __ \   / __ )   / __ \
                    / /    / / / /   / /_/ /  / __  |  / / / /
                   / /    / /_/ /   / _, _/  / /_/ /  / /_/ /
                  /_/     \____/   /_/ |_|  /_____/   \____/
                    ____     ___      ______   ______   ____
                   / __ \   /   |    / ____/  / ____/  / __ \
                  / /_/ /  / /| |   / /      / __/    / /_/ /
                 / _, _/  / ___ |  / /___   / /___   / _, _/
                /_/ |_|  /_/  |_|  \____/  /_____/  /_/ |_|
          ______   _  __  ______   ____     ______   __  ___   ______
~~~~~~~~~/ ____/ ~| |/ /~/_  __/ ~/ __ \ ~~/ ____/ ~/  |/  / ~/ ____/ 
~~~~~~~~/ __/ ~~~~|   / ~~/ / ~~~/ /_/ / ~/ __/ ~~~/ /|_/ / ~/ __/
~~~~~~~/ /___ ~~~/   | ~~/ / ~~~/ _, _/ ~/ /___ ~~/ /  / / ~/ /___
~~~~~~/_____/ ~~/_/|_| ~/_/ ~~~/_/~|_| ~/_____/ ~/_/  /_/ ~/_____/

             Motion Nunchuck Ninja Edition 2.1 - Insert Coin
   Published by Mechanum Industries for PC-DOS, Amega, VIC 20, and iPhone 5c