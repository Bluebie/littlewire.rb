Little Wire is a little multiheaded animal who pokes in a USB port, and uploads
programs to AVR and PIC chips. But Little Wire does so much more - and that's
what this library is about. The [littlewire.cc](http://littlewire.cc/) gadget
exposes four digital wires and a five volt power supply. Those four wires can
each be individually controlled, with three capable of varying brightness of
lights, two capable of controlling motors and servos, two 10-bit analog inputs,
a temperature sensor, a Serial Peripheral Interface, an i2c interface, and a
1-wire interface.

Eventually littlewire.rb hopes to share fun, simple, principal of least surprise
ruby interfaces to all of these.


### a blinky ###

    require 'littlewire'
    
    wire = LittleWire.connect # connects to the first Little Wire on your computer
    
    loop do
      wire.digital_write :pin3, :vcc # connect pin3 to 5v
      sleep 0.5
      wire.digital_write :pin3, :gnd # connect pin3 to ground
      sleep 0.5
    end

And so it is that the ruby on the computer did remotely control the Little Wire's
digital port. Don't forget a resistor for that LED of yours! If you don't have a
resistor handy, add `wire.pin_mode :pin3 => :input` before `loop do` to use
Little Wire's internal 20kohm resistor and keep that light shining.


### a philosophy ###

Little Wire is such a small creature it's possible perhaps to implement every way
you might want to use it! Every method name and every symbol. I've tried to do this
a bit. My hope is that you'll play with littlewire in irb (or better yet 
[pry](http://pryrepl.org)) and everything you try just works. To that end, littlewire
supports `ruby_style_methods` and `wiringStyleMethods`, and has methods like
`digitalWrite(:pin1, true)` - familliar to arduinoers but also syntaxes like
`mywire[:d1] = true`. Initialization sequences automatically run the moment you try
to use features, and they always try to make sure littlewire is correctly configured
for the task at hand, while not making any unnecessary requests. The only thing
littlewire.rb doesn't do (yet) is program other chips - use avrdude for that.


### what's it good for? ###

You could use the three pulse width modulated analog outputs to control an RGB light
adjusting the mood of your batcave at the click of a button. Hook it up to displays,
memory, sensors, iButtons, RFID readers, digital radios, motors, switches, fairy
lights... whatever floats your boat really. The possabilities are not especially
limited. Most projects you might use an Arduino for can be done with a Little Wire
if you don't mind leaving a computer turned on connected to it, and with the advent
of Raspberry Pi, that's not all that bad of an idea. I use my Little Wire to quickly
test ideas before changing them to C and uploading them to cheaper avr tiny chips
(also using the Little Wire to program them)


### a warning ###

littlewire.rb is experimental (till it is released as 1.0 via rubygems) and there's
a pretty good chance the API will change a bit until then. Not to worry - rubygems
have a mechanism for you to [require a specific version][1] of littlewire.rb,
ensuring your programs always work, so you can start building stuff on it today!

[1]: http://docs.rubygems.org/read/chapter/4#page71 "RubyGems Documentation"

