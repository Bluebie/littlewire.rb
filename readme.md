LittleWire is a little multiheaded animal who pokes in a USB port, and uploads
programs to AVR chips. But LittleWire does so much more - and that's what this
library is about. The littlewire.cc gadget exposes four digital wires and a five
volt power supply. Those four wires can each be individually controlled, with
three capable of varying brightness of lights, two capable of controlling motors
and servos, two 10-bit analog inputs, a temperature sensor, a Serial Peripheral
Interface, an i2c interface, and a 1-wire interface.

Eventually littlewire.rb hopes to share fun, simple, principal of least surprise
ruby interfaces to all of these.

LittleWire.rb has not yet reached it's first rubygem release, and the API may
have breaking changes until then - it is being shared for interested people to
think about and play with.


### A blinky ###

```
require 'littlewire'

wire = LittleWire.connect # connects to the first LittleWire on your computer

loop do
  wire.digital_write :pin3, true # connect pin3 to 5v
  sleep 0.5
  wire.digital_write :pin3, false # connect pin3 to ground
  sleep 0.5
end
```

And so it is that the ruby on the computer did remotely control the LittleWire's
digital port. Don't forget a resistor for that LED of yours!


### A Philosophy ###

LittleWire is such a small creature it's possible perhaps to implement every way
you might want to use it! Every method name and every symbol. I've tried to do this
a bit. My hope is that you'll play with LittleWire in irb (or better yet pry) and
everything you try just works. To that end, LittleWire supports ruby_style_methods
and wiringStyleMethods, and has methods like digitalWrite(:pin1, true) - familliar
to arduinoers but also syntaxes like mywire[:d1] = true. Initialization sequences
automatically run the moment you try to use features, and they always try to make
sure littlewire is correctly configured for the task at hand, while not making any
unnecessary requests. The only thing littlewire.rb doesn't do (yet) is program other
chips - use avrdude for that.


