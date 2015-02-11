##
# TRACK 2
# RHAPSODY IN GREY (datadrivendj.com/tracks/brain)
# Brian Foo (brianfoo.com)
# This file builds the sequence file for use with ChucK from the data supplied
##

# Library dependancies
import csv
import json
import math
import os
import time

# Config
BPM = 75 # Beats per minute, e.g. 60, 75, 100, 120, 150
DIVISIONS_PER_BEAT = 16 # e.g. 4 = quarter notes, 8 = eighth notes, etc
VARIANCE_MS = 10 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
PRECISION = 6 # decimal places after 0 for reading value
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
EEG_INPUT_FILE = 'data/eeg.csv'
REPORT_SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
REPORT_SUMMARY_CHANNEL_OUTPUT_FILE = 'data/report_channel_summary.csv'
REPORT_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/eeg.json'
INSTRUMENTS_DIR = 'instruments/'
WRITE_SEQUENCE = True
WRITE_REPORT = False
WRITE_JSON = False
LABELS = ['Time', 'FP1-F7', 'F7-T7', 'T7-P7', 'P7-O1', 'FP1-F3', 'F3-C3', 'C3-P3', 'P3-O1', 'FP2-F4', 'F4-C4', 'C4-P4', 'P4-O2', 'FP2-F8', 'F8-T8', 'T8-P8', 'P8-O2', 'FZ-CZ', 'CZ-PZ']

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
MEASURE_MS = BEAT_MS * 4.0
ROUND_TO_NEAREST = round(BEAT_MS/DIVISIONS_PER_BEAT)
CHANNEL_COUNT = len(LABELS) - 1

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat)')

# Initialize Variables
instruments = []
eeg = []
eeg_min = []
eeg_max = []
measures = []
abs_min = 0
abs_max = 0
sequence = []
hindex = 0
total_ms = 0

# For creating pseudo-random numbers
def halton(index, base):
	result = 0.0
	f = 1.0 / base
	i = 1.0 * index
	while(i > 0):
		result += f * (i % base)	
		i = math.floor(i / base)
		f = f / base
	return result

# Mean of list
def mean(data):
    if iter(data) is data:
			data = list(data)
    n = len(data)
    if n < 1:
			return 0
    else:
			return sum(data)/n

# Variance of list
def variance(data):
    if iter(data) is data:
			data = list(data)
    n = len(data)
    if n < 1:
			return 0
    else:
			c = mean(data)
			ss = sum((x-c)**2 for x in data)
			ss -= sum((x-c) for x in data)**2/len(data)
			return ss/n

# Standard deviation of list
def stdev(data):
    var = variance(data)
    return math.sqrt(var)

# Find index of first item that matches value
def findInList(list, key, value):
	found = -1
	for index, item in enumerate(list):
		if item[key] == value:
			found = index
			break
	return found

def roundToNearest(n, nearest):
	return 1.0 * round(1.0*n/nearest) * nearest

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,channel,variance_min,variance_max,wavelength_min,wavelength_max,file,from_gain,to_gain,from_tempo,to_tempo,gain_phase,tempo_phase,tempo_offset,interval_phase,interval,interval_offset,active in r:
		if file and int(active):
			index = len(instruments)
			# build instrument object
			instrument = {
				'index': index,
				'name': name,
				'channel': channel,
				'variance_min': float(variance_min),
				'variance_max': float(variance_max),
				'wavelength_min': float(wavelength_min),
				'wavelength_max': float(wavelength_max),
				'file': INSTRUMENTS_DIR + file,
				'from_gain': round(float(from_gain), 2),
				'to_gain': round(float(to_gain), 2),
				'from_tempo': float(from_tempo),
				'to_tempo': float(to_tempo),
				'gain_phase': int(gain_phase),
				'tempo_phase': int(tempo_phase),
				'from_beat_ms': int(round(BEAT_MS/float(from_tempo))),
				'to_beat_ms': int(round(BEAT_MS/float(to_tempo))),
				'tempo_offset': float(tempo_offset),
				'interval_ms': int(int(interval_phase)*BEAT_MS),
				'interval': int(interval),
				'interval_offset': int(interval_offset)
			}
			# add instrument to instruments
			instruments.append(instrument)

# Convert a row of values to values between 0 and 1
def normalizeRow(row, min_value, max_value):
	global PRECISION
	normalized_row = []
	delta = max_value - min_value
	for i, col in enumerate(row):
		if i > 0:
			normalized_row.append(round(1.0 * (col - min_value) / delta, PRECISION))
		else:
			normalized_row.append(col)
	return normalized_row

def getWavelength(data, _min, _max, _stdev):
	waves = []
	start = -1
	bottom_found = False
	end = -1
	data_len = len(data)
	for index, value in enumerate(data):
		# Look for the first peak
		if value > (_max-_stdev) and start < 0:
			start = index
		# Look for the bottom crest
		elif value < (_min+_stdev) and start >= 0 and not bottom_found and end < 0:
			bottom_found = True
		# Look for second peak
		elif bottom_found and value > (_max-_stdev) and end < 0:
			end = index
			# Add wave to list and reset
			waves.append(1.0 * (end - start) / data_len)
			start = -1
			bottom_found = False
			end = -1
	# wave(s) found, return average length
	if len(waves) > 0:
		return mean(waves)
	else:
		return -1

# Read eeg from file
with open(EEG_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	last_ms = 0
	measure = []
	next_measure = MEASURE_MS
	for t,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16,s17,s18,s19,s20,s21,s22,s23 in r:
		ms = int(t)
		row = [ms,float(s1),float(s2),float(s3),float(s4),float(s5),float(s6),float(s7),float(s8),float(s9),float(s10),float(s11),float(s12),float(s13),float(s14),float(s15),float(s16),float(s17),float(s18)]
		# get row with minimum values
		if ms <= -2:
			eeg_min = row
			abs_min = min(eeg_min)
		# get row with maximum values
		elif ms <= -1:
			eeg_max = row
			abs_max = max(eeg_max)
		# all other rows
		else:
			normalized_row = normalizeRow(row, abs_min, abs_max)
			eeg.append(normalized_row)
			if ms >= next_measure:
				measures.append({								
					"readings": measure,
					"channels": [],
					"duration": MEASURE_MS
				})
				measure = []
				next_measure += MEASURE_MS
			else:
				measure.append(normalized_row[1:])
			total_ms += (ms - last_ms)
			last_ms = ms
	# Add the last measure
	if len(measure) > 0:
		measures.append({				
			"readings": measure,
			"channels": [],
			"duration": total_ms - MEASURE_MS * len(measures)
		})

# Keep track of min/max stdev for normalization
min_stdev = 0
max_stdev = 0
min_mean_stdev = 0
max_mean_stdev = 0
min_stdev2 = 0
max_stdev2 = 0
min_wavelength = 0
max_wavelength = 0
			
# Go through each measure
for mindex, measure in enumerate(measures):
	channels = []
	stdevs = []
	maxs = []
	wavelengths = []
	# Create an array of channel-value arrays
	for channel in range(CHANNEL_COUNT):
		channels.append([])
	for reading in measure["readings"]:
		for channel, value in enumerate(reading):
			channels[channel].append(value)
	# For each channel
	for cindex, channel in enumerate(channels):
		# Calculate stdev, min/max, wavelength
		_stdev = stdev(channel)
		_min = min(channel)
		_max = max(channel)
		_wavelength = getWavelength(channel, _min, _max, _stdev)
		stdevs.append(_stdev)
		maxs.append(_max)
		if _wavelength >= 0:
			wavelengths.append(_wavelength)
			# Keep track of max/mins
			if _wavelength > max_wavelength:
				max_wavelength = _wavelength
			if _wavelength < min_wavelength or min_wavelength==0:
				min_wavelength = _wavelength
		if _stdev > max_stdev:
			max_stdev = _stdev
		if _stdev < min_stdev or min_stdev==0:
			min_stdev = _stdev
		# Add to channel list to measure
		measures[mindex]["channels"].append({
			"index": cindex + 1,
			"name": LABELS[cindex + 1],
			"stdev": _stdev,
			"max": _max,
			"wavelength": _wavelength
		})
	# Calculate max/means/stdevs
	mean_stdev = mean(stdevs)
	stdev_stdev = stdev(stdevs)
	measures[mindex]["max"] = max(maxs)
	measures[mindex]["mean_stdev"] = mean_stdev
	measures[mindex]["mean_wavelength"] = mean(wavelengths)
	measures[mindex]["stdev_stdev"] = stdev_stdev
	# Keep track of min/max
	if mean_stdev > max_mean_stdev:
		max_mean_stdev = mean_stdev
	if mean_stdev < min_mean_stdev or min_mean_stdev==0:
		min_mean_stdev = mean_stdev
	if stdev_stdev > max_stdev2:
		max_stdev2 = stdev_stdev
	if stdev_stdev < min_stdev2 or min_stdev2==0:
		min_stdev2 = stdev_stdev

# Normalize all values in measures
for mindex, measure in enumerate(measures):
	stdev_delta = max_stdev - min_stdev
	stdev_mean_delta = max_mean_stdev - min_mean_stdev
	stdev2_delta = max_stdev2 - min_stdev2
	wavelength_delta = max_wavelength - min_wavelength
	# Normalize all values to between 0 and 1
	measures[mindex]["mean_stdev"] = 1.0 * (measure["mean_stdev"]-min_mean_stdev) / stdev_mean_delta
	measures[mindex]["stdev_stdev"] = 1.0 * (measure["stdev_stdev"]-min_stdev2) / stdev2_delta
	measures[mindex]["mean_wavelength"] = 1.0 * (measure["mean_wavelength"]-min_wavelength) / wavelength_delta
	for cindex, channel in enumerate(measure["channels"]):
		measures[mindex]["channels"][cindex]["stdev"] = 1.0 * (channel["stdev"]-min_stdev) / stdev_delta
		if channel["wavelength"] >= 0:
			measures[mindex]["channels"][cindex]["wavelength"] = 1.0 * (channel["wavelength"]-min_wavelength) / wavelength_delta

# Returns list of valid instruments given channel, phase, and measure data
def getChannelInstruments(_instruments, _channel, _measure):
	valid_instruments = []
	for instrument in _instruments:
		if instrument["channel"]==_channel["name"] and _channel["stdev"]>=instrument["variance_min"] and _channel["stdev"]<instrument["variance_max"] and _channel["wavelength"]>=instrument["wavelength_min"] and _channel["wavelength"]<instrument["wavelength_max"]:
			valid_instruments.append(instrument)
	return valid_instruments
		
# Determine instruments
for mindex, measure in enumerate(measures):
	_instruments = []
	for cindex, channel in enumerate(measure["channels"]):
		# Add instruments based on channel, phase, measure
		_instruments.extend(getChannelInstruments(instruments, channel, measure))
	measures[mindex]["instruments"] = _instruments

# Multiplier based on sine curve
def getMultiplier(percent_complete):
	radians = percent_complete * math.pi
	multiplier = math.sin(radians)
	if multiplier < 0:
		multiplier = 0.0
	elif multiplier > 1:
		multplier = 1.0
	return multiplier

# Retrieve gain based on current beat
def getGain(instrument, beat):
	beats_per_phase = instrument['gain_phase']
	percent_complete = float(beat % beats_per_phase) / beats_per_phase
	multiplier = getMultiplier(percent_complete)
	from_gain = instrument['from_gain']
	to_gain = instrument['to_gain']
	min_gain = min(from_gain, to_gain)
	gain = multiplier * (to_gain - from_gain) + from_gain
	gain = max(min_gain, round(gain, 2))
	return gain

# Get beat duration in ms based on current point in time
def getBeatMs(instrument, beat, round_to):	
	from_beat_ms = instrument['from_beat_ms']
	to_beat_ms = instrument['to_beat_ms']
	beats_per_phase = instrument['tempo_phase']
	percent_complete = float(beat % beats_per_phase) / beats_per_phase
	multiplier = getMultiplier(percent_complete)
	ms = multiplier * (to_beat_ms - from_beat_ms) + from_beat_ms
	ms = int(roundToNearest(ms, round_to))
	return ms

# Return if the instrument should be played in the given interval
def isValidInterval(instrument, elapsed_ms):
	interval_ms = instrument['interval_ms']
	interval = instrument['interval']
	interval_offset = instrument['interval_offset']	
	return int(math.floor(1.0*elapsed_ms/interval_ms)) % interval == interval_offset

# Add beats to sequence
def addBeatsToSequence(instrument, duration, ms, beat_ms, round_to):
	global sequence
	global hindex
	offset_ms = int(instrument['tempo_offset'] * beat_ms)
	ms += offset_ms
	previous_ms = int(ms)
	from_beat_ms = instrument['from_beat_ms']
	to_beat_ms = instrument['to_beat_ms']
	min_ms = min(from_beat_ms, to_beat_ms)
	remaining_duration = int(duration)
	elapsed_duration = offset_ms
	while remaining_duration >= min_ms:
		elapsed_ms = int(ms)
		elapsed_beat = int((elapsed_ms-previous_ms) / beat_ms)
		this_beat_ms = getBeatMs(instrument, elapsed_beat, round_to)
		# add to sequence if in valid interval
		if isValidInterval(instrument, elapsed_ms):
			h = halton(hindex, 3)
			variance = int(h * VARIANCE_MS * 2 - VARIANCE_MS)
			sequence.append({
				'instrument_index': instrument['index'],
				'instrument': instrument,
				'position': 0,
				'gain': getGain(instrument, elapsed_beat),
				'rate': 1,
				'elapsed_ms': elapsed_ms + variance
			})
			hindex += 1
		remaining_duration -= this_beat_ms
		elapsed_duration += this_beat_ms
		ms += this_beat_ms

# Build main sequence
for instrument in instruments:
	ms = 0
	queue_duration = 0
	# Each measure
	for measure in measures:
		# Check if instrument is in this measure
		instrument_index = findInList(measure['instruments'], 'index', instrument['index'])
		# Instrument not here, just add the measure duration and continue
		if instrument_index < 0 and queue_duration > 0:
			addBeatsToSequence(instrument, queue_duration, ms, BEAT_MS, ROUND_TO_NEAREST)
			ms += queue_duration + measure['duration']
			queue_duration = 0
		elif instrument_index < 0:
			ms += measure['duration']
		else:
			queue_duration += measure['duration']
	if queue_duration > 0:
		addBeatsToSequence(instrument, queue_duration, ms, BEAT_MS, ROUND_TO_NEAREST)
		
# Calculate total time
total_seconds = int(1.0*total_ms/1000)
print('Total sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + '(' + str(total_seconds) + 's)')

# Sort sequence
sequence = sorted(sequence, key=lambda k: k['elapsed_ms'])

# Add milliseconds to sequence
elapsed = 0
for index, step in enumerate(sequence):
	sequence[index]['milliseconds'] = step['elapsed_ms'] - elapsed
	elapsed = step['elapsed_ms']

# Write instruments to file
if WRITE_SEQUENCE and len(instruments) > 0:
	with open(INSTRUMENTS_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)	
		for index, instrument in enumerate(instruments):
			w.writerow([index])
			w.writerow([instrument['file']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote instruments to file: '+INSTRUMENTS_OUTPUT_FILE)

# Write sequence to file
if WRITE_SEQUENCE and len(sequence) > 0:
	with open(SEQUENCE_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)	
		for step in sequence:
			w.writerow([step['instrument_index']])
			w.writerow([step['position']])
			w.writerow([step['gain']])
			w.writerow([step['rate']])
			w.writerow([step['milliseconds']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote sequence to file: '+SEQUENCE_OUTPUT_FILE)

# Write summary files
if WRITE_REPORT:
	with open(REPORT_SUMMARY_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(['Time', 'Mean-Stdev', 'Stdev-Stdev', 'Mean-Wavelength', 'Duration'])
		for mindex, measure in enumerate(measures):
			elapsed = mindex * MEASURE_MS
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, measure['mean_stdev'], measure['stdev_stdev'], measure['mean_wavelength'], int(measure['duration'])])
		print('Successfully wrote summary file: '+REPORT_SUMMARY_OUTPUT_FILE)
	with open(REPORT_SUMMARY_CHANNEL_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(LABELS)
		for mindex, measure in enumerate(measures):
			elapsed = mindex * MEASURE_MS
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			channels = [elapsed_f]
			for channel in measure["channels"]:
				channels.append(channel["stdev"])
			w.writerow(channels)
		print('Successfully wrote channel summary file: '+REPORT_SUMMARY_CHANNEL_OUTPUT_FILE)

# Write sequence report to file
if WRITE_REPORT and len(sequence) > 0:
	with open(REPORT_SEQUENCE_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(['Time', 'Instrument', 'Gain'])
		for step in sequence:
			instrument = instruments[step['instrument_index']]
			elapsed = step['elapsed_ms']
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, instrument['file'], step['gain']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote sequence report to file: '+REPORT_SEQUENCE_OUTPUT_FILE)

# Write JSON data for the visualization
if WRITE_JSON:
	json_data = eeg
	json_data.insert(0, LABELS)
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(json_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
