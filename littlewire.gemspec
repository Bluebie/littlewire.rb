require './lib/littlewire/version.rb'

Gem::Specification.new do |s|
  s.name = 'littlewire'
  s.version = LittleWire::Version
  s.summary = "A tiny library for littlewire.cc usb devices"
  s.author = 'Bluebie'
  s.email = "a@creativepony.com"
  s.homepage = "http://creativepony.com/littlewire/"
  s.description = "A little library for a little wire. Providing a pure ruby interface (via the nonpure libusb gem) to " +
  "littlewire.cc's wonderful gadget. littlewire.rb provides general purpose digital IO, pulse width modulation analog " +
  "outputs, analog inputs, SPI, I2C, One Wire, and rough servo control via a friendly interface which responds both to " +
  "familiar Wiring/Arduino style methods and a more concise ruby alternative. LittleWire can be installed on to Digispark" +
  "devices, offering a very extensive firmata-style option for digispark users."
  s.files = Dir['lib/**/*.rb'] + ['readme.md', 'license.txt'] + Dir['examples/**/*.rb'] + Dir['bin/**/*.rb'] + Dir['firmware/**/*.hex']
  s.executables << 'littlewire.rb'
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 1.9.1'
  s.licenses = ['CC0', 'Unlicense', 'Public Domain']
  
  s.rdoc_options << '--main' << 'lib/littlewire.rb'
  
  s.add_dependency 'libusb', '>= 0.2.0' # for talking to hardware
  s.add_dependency 'colorist', '>= 0.0.2' # for interpreting colors in the ws2812 stuff
  s.add_dependency 'thor', '>= 0.18.1' # cli stuff for cli app
  #s.add_dependency 'colored', '>= 1.2' # colorful output in cli app
end
