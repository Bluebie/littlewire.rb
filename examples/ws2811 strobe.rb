require 'littlewire'
wire = LittleWire.connect
pin = :pin1
num_leds = 10
MaxBPM = 500

strobe_duration = 0.01
bpm = 30

Thread.start do
  loop do
    print "Enter BPM: "
    new_bpm = (gets.to_f rescue bpm)
    new_bpm = MaxBPM if new_bpm > MaxBPM
    bpm = new_bpm
    puts "Set to #{bpm}"
  end
end

loop do
  wire.ws2811.colors = ['white'] * num_leds
  wire.ws2811.output pin
  sleep(strobe_duration)
  
  wire.ws2811.colors = ['black'] * num_leds
  wire.ws2811.output pin
  blackout_duration = (60.0 / bpm) - strobe_duration
  sleep((60.0 / bpm) - strobe_duration) if blackout_duration > 0
end