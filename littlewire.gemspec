Gem::Specification.new do |s|
  s.name = 'littlewire'
  s.version = '0.9'
  s.summary = "A tiny library for littlewire.cc usb devices"
  s.author = 'Bluebie'
  s.email = "a@creativepony.com"
  s.homepage = "http://creativepony.com/littlewire/"
  s.description = "A little library for a little wire. Providing a pure ruby interface (via the nonpure libusb gem) to " +
  "littlewire.cc's wonderful gadget. littlewire.rb provides general purpose digital IO, pulse width modulation analog " +
  "outputs, analog inputs, SPI, I2C, One Wire, and rough servo control via a friendly interface which responds both to " +
  "familliar Wiring/Arduino style methods and a more concise ruby alternative."
  s.files = Dir['lib/**.rb'] + ['readme.md', 'license.txt'] + Dir['examples/**.rb']
  s.require_paths = ['lib']
  
  s.rdoc_options << '--main' << 'lib/littlewire.rb'
  
  s.add_dependency 'libusb', '>= 0.2.0'
end