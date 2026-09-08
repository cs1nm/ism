extends Node

# Simple sound system using AudioStreamGenerator

var audio_player: AudioStreamPlayer = null

func _ready():
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "SoundPlayer"
	add_child(audio_player)

func play_sound(type: String):
	if not audio_player:
		return
	
	var stream = _generate_sound(type)
	if stream:
		audio_player.stream = stream
		audio_player.play()

func _generate_sound(type: String) -> AudioStream:
	match type:
		"collect":
			return _generate_tone(440.0, 0.1, 0.3)  # A4, short
		"sell":
			return _generate_tone(880.0, 0.15, 0.4)  # A5, medium
		"hit":
			return _generate_noise(0.1, 0.5)  # Short noise
		"enemy_die":
			return _generate_tone(220.0, 0.2, 0.3)  # A3, longer
		"upgrade":
			return _generate_chord([440.0, 554.0, 659.0], 0.3, 0.3)  # A major
		"achievement":
			return _generate_chord([523.0, 659.0, 784.0], 0.5, 0.4)  # C major
		"portal":
			return _generate_sweep(200.0, 800.0, 0.5, 0.3)  # Frequency sweep
	
	return null

func _generate_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(duration * sample_rate)
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var data = PackedByteArray()
	data.resize(samples)
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var envelope = 1.0 - (float(i) / samples)  # Fade out
		var value = sin(t * freq * TAU) * envelope * volume
		data[i] = int((value * 0.5 + 0.5) * 255)
	
	wav.data = data
	return wav

func _generate_noise(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(duration * sample_rate)
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var data = PackedByteArray()
	data.resize(samples)
	
	for i in range(samples):
		var envelope = 1.0 - (float(i) / samples)
		var value = (randf() * 2.0 - 1.0) * envelope * volume
		data[i] = int((value * 0.5 + 0.5) * 255)
	
	wav.data = data
	return wav

func _generate_chord(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(duration * sample_rate)
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var data = PackedByteArray()
	data.resize(samples)
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var envelope = 1.0 - (float(i) / samples)
		var value = 0.0
		for freq in freqs:
			value += sin(t * freq * TAU)
		value = (value / freqs.size()) * envelope * volume
		data[i] = int((value * 0.5 + 0.5) * 255)
	
	wav.data = data
	return wav

func _generate_sweep(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(duration * sample_rate)
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var data = PackedByteArray()
	data.resize(samples)
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples
		var freq = lerp(freq_start, freq_end, progress)
		var envelope = 1.0 - progress
		var value = sin(t * freq * TAU) * envelope * volume
		data[i] = int((value * 0.5 + 0.5) * 255)
	
	wav.data = data
	return wav
