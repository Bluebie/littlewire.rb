require 'littlewire'
wire = LittleWire.connect
pin = :pin4
num_leds = 19
MaxBPM = 500
AveragedTaps = 8

puts "Outputtting data to LittleWire pin named '#{pin}'"

strobe_duration = 0.01
bpm = 30
last_tap = Time.now.to_f
tap_bpms = []
last_strobe = Time.now.to_f
reset = false

wire.ws2811(pin).black!

puts "Enter BPM and press enter to set it"
puts "Or, tap enter key (leave blank) to the beat to detect BPM"
puts "Or, enter z to halve current bpm and x to double it, followed by enter"

Thread.abort_on_exception = true
interface = Thread.start do
  loop do
    print "Enter BPM: "
    str = gets.strip
    time = Time.now.to_f
    new_bpm = bpm
    
    if str == 'z'
      new_bpm = bpm / 2.0
      tap_bpms.map! { |x| x / 2.0 }
      
    elsif str == 'x'
      new_bpm = bpm * 2.0
      tap_bpms.map! { |x| x * 2 }
      
    elsif str.empty?
      # calculate bpm from last tap and this one
      tap_bpm = 60.0 / (time - last_tap)
      
      # add tap to list and compute average
      tap_bpms.push tap_bpm
      tap_bpms = tap_bpms.last(AveragedTaps)
      
      # compute average
      avg = tap_bpms.reduce(:+) / tap_bpms.length
      nearest_subset = tap_bpms.sort { |a,b| (a - avg).abs <=> (b - avg).abs }.first(tap_bpms.length / 2)
      
      new_bpm = nearest_subset.reduce(:+) / nearest_subset.length if nearest_subset.length >= 2
      
      # because strobes are mainly used with electro music, and electro music is
      # usually whole number BPMs, round it to the nearest full bpm
      new_bpm = new_bpm.round
      
      # set last strobe and last tap to now, so a new strobe begins immediately
      last_strobe = last_tap = time
      reset = true # ask main thread to skip timers and start a new strobe now
      
      puts "TAP!"
    else # numbers were typed in presumably!
      new_bpm = (str.to_f rescue bpm)
      tap_bpms.clear # reset tap bpm system
    end
    
    new_bpm = MaxBPM if new_bpm > MaxBPM
    new_bpm = 30.0 if new_bpm < 30.0
    bpm = new_bpm
    puts "Set to #{bpm}"
  end
end

loop do
  last_strobe = Time.now.to_f
  wire.ws2811(pin).set ['white'] * num_leds
  
  while Time.now.to_f - last_strobe <= strobe_duration and !reset
    Thread.pass
  end
  
  wire.ws2811(pin).set ['black'] * num_leds
  blackout_duration = (60.0 / bpm) - strobe_duration
  
  while Time.now.to_f - last_strobe <= 60.0 / bpm and !reset
    Thread.pass
  end
  
  last_strobe += 60.0 / bpm
  
  #sleep((60.0 / bpm) - strobe_duration) if blackout_duration > 0
  reset = false
end