##
# TRACK 3
# AIR PLAY (datadrivendj.com/tracks/smog)
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
BPM = 120 # Beats per minute, e.g. 60, 75, 100, 120, 150
READINGS_PER_BEAT = 2
DIVISIONS_PER_BEAT = 4 # e.g. 4 = quarter notes, 8 = eighth notes, etc
VARIANCE_MS = 10 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 0.4 # base gain
TEMPO = 1.0 # base tempo
DATE_FORMAT = "%Y-%m-%d" # %Y-%m-%d %H:%M
DATE_FORMAT_DISPLAY = "%b %d, %Y"
PM_THRESHOLD = 50
PM_UNIT = 1

# Files
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
PM25_INPUT_FILE = 'data/pm25_readings.csv'
REPORT_SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
REPORT_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/pm25_data.json'
INSTRUMENTS_DIR = 'instruments/'

# Output options
WRITE_SEQUENCE = True
WRITE_REPORT = True
WRITE_JSON = True

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
ROUND_TO_NEAREST = round(BEAT_MS/DIVISIONS_PER_BEAT)

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat)')

# Initialize Variables
instruments = []
pm25 = []
sequence = []
pm25_min = None
pm25_max = None
pm25_residue_min = None
pm25_residue_max = None
pm25_count = 0
hindex = 0
total_beats = 0
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

# Find index of first item that matches value
def findInList(list, key, value):
	found = -1
	for index, item in enumerate(list):
		if item[key] == value:
			found = index
			break
	return found

# round {n} to nearest {nearest}
def roundToNearest(n, nearest):
	return 1.0 * round(1.0*n/nearest) * nearest
	
# ceil {n} to nearest {nearest}
def ceilToNearest(n, nearest):
	return 1.0 * math.ceil(1.0*n/nearest) * nearest

# decrement each element in list
def decrementList(list, amount, min_amount=0):
	new_list = []
	for item in list:
		item -= amount
		if item > min_amount:
			new_list.append(item)
	return new_list

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,pm25_min,pm25_max,residue_min,residue_max,file,from_gain,to_gain,round_to,from_tempo,to_tempo,tempo_offset,interval_phase,interval,interval_offset,active in r:
		if int(active):
			index = len(instruments)
			# build instrument object
			instrument = {
				'index': index,
				'pm25_min': float(pm25_min),
				'pm25_max': float(pm25_max),
				'residue_min': float(residue_min),
				'residue_max': float(residue_max),
				'name': name,
				'file': INSTRUMENTS_DIR + file,
				'from_gain': float(from_gain) * GAIN,
				'to_gain': float(to_gain) * GAIN,
				'round_to_ms': float(round_to) * BEAT_MS,
				'from_tempo': float(from_tempo) * TEMPO,
				'to_tempo': float(to_tempo) * TEMPO,
				'tempo_offset': float(tempo_offset),
				'interval_ms': int(int(interval_phase)*BEAT_MS),
				'interval': int(interval),
				'interval_offset': int(interval_offset),
				'from_beat_ms': int(round(BEAT_MS/(float(from_tempo)*TEMPO))),
				'to_beat_ms': int(round(BEAT_MS/(float(to_tempo)*TEMPO))),
			}
			# add instrument to instruments
			instruments.append(instrument)

# Read PM2.5 from file
pm_residue = []
with open(PM25_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	pm25_min = int(next(r, None)[-1])
	pm25_max = int(next(r, None)[-1])
	pm25_count = int(next(r, None)[-1])
	pm_residue_value = 0
	for _datetime, _value in r:
		datetime = time.strptime(_datetime, DATE_FORMAT)
		pm_value = int(_value)
		if pm_value > PM_THRESHOLD:
			pm_residue.append(pm_value)
			pm_residue_value = sum(pm_residue)
			# Track min/max residue
			if pm25_residue_max is None or pm_residue_value > pm25_residue_max:
				pm25_residue_max = pm_residue_value
			if pm25_residue_min is None or pm_residue_value < pm25_residue_min:
				pm25_residue_min = pm_residue_value
		pm25.append({
			'date': time.strftime(DATE_FORMAT_DISPLAY, datetime).replace(' 0', ' '),
			'val': pm_value,
			'residue': pm_residue_value
		})
		pm_residue = decrementList(pm_residue, PM_UNIT)

# Report PM2.5 data
print('Retrieved PM2.5 data with '+ str(pm25_count) + ' data points')
print('ug/m^3 range: ['+str(pm25_min)+','+str(pm25_max)+']')
print('Max residue: '+str(pm25_residue_max))

# Calculate total time
total_beats = 1.0 * pm25_count / READINGS_PER_BEAT
total_ms = total_beats * BEAT_MS
total_seconds = int(1.0*total_ms/1000)
READING_MS = total_ms / len(pm25)
MIN_READING_MS = READING_MS * 2
MAX_READING_MS = READING_MS * 40
print('Main sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + '(' + str(total_seconds) + 's, '+str(total_beats)+' beats)')
print(str(READING_MS)+'ms per reading')

# Multiplier based on sine curve
def getMultiplier(percent_complete, rad=1.0):
	radians = percent_complete * (math.pi * rad)
	multiplier = math.sin(radians)
	if multiplier < 0:
		multiplier = 0.0
	elif multiplier > 1:
		multplier = 1.0
	return multiplier

# Retrieve gain based on current beat
def getGain(instrument, percent_complete):
	multiplier = getMultiplier(percent_complete)
	from_gain = instrument['from_gain']
	to_gain = instrument['to_gain']
	min_gain = min(from_gain, to_gain)
	gain = multiplier * (to_gain - from_gain) + from_gain
	gain = max(min_gain, round(gain, 2))
	return gain

# Get beat duration in ms based on current point in time
def getBeatMs(instrument, percent_complete, round_to):
	multiplier = getMultiplier(percent_complete, 0.5)
	from_beat_ms = instrument['from_beat_ms']
	to_beat_ms = instrument['to_beat_ms']	
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
	if instrument['round_to_ms'] > 0:
		ms = roundToNearest(ms, instrument['round_to_ms'])
	previous_ms = int(ms)
	from_beat_ms = instrument['from_beat_ms']
	to_beat_ms = instrument['to_beat_ms']
	min_ms = min(from_beat_ms, to_beat_ms)
	remaining_duration = int(duration)
	elapsed_duration = offset_ms
	while remaining_duration >= min_ms:
		elapsed_ms = int(ms)
		elapsed_beat = int((elapsed_ms-previous_ms) / beat_ms)
		percent_complete = 1.0 * elapsed_duration / duration
		this_beat_ms = getBeatMs(instrument, percent_complete, round_to)
		# add to sequence if in valid interval
		if isValidInterval(instrument, elapsed_ms):
			h = halton(hindex, 3)
			variance = int(h * VARIANCE_MS * 2 - VARIANCE_MS)
			sequence.append({
				'instrument_index': instrument['index'],
				'instrument': instrument,
				'position': 0,
				'rate': 1,
				'gain': getGain(instrument, percent_complete),
				'elapsed_ms': max([elapsed_ms + variance, 0])
			})
			hindex += 1
		remaining_duration -= this_beat_ms
		elapsed_duration += this_beat_ms
		ms += this_beat_ms

# Get/set normalized values		
for ri, reading in enumerate(pm25):	
	nval = (1.0 * reading['val'] - pm25_min) / (pm25_max - pm25_min)
	nresidue = (1.0 * reading['residue'] - pm25_residue_min) / (pm25_residue_max - pm25_residue_min)
	pm25[ri]['nval'] = nval
	pm25[ri]['nresidue'] = nresidue

# Build Sequence
for instrument in instruments:
	ms = 0
	queue_duration = 0
	# Each reading
	for ri, reading in enumerate(pm25):
		# Check if instrument is valid for this reading
		nval = reading['nval']
		nresidue = reading['nresidue']
		is_valid = (nval >= instrument['pm25_min'] and nval < instrument['pm25_max'] and nresidue >= instrument['residue_min'] and nresidue < instrument['residue_max'])
		# Instrument not here, just add the reading duration and continue
		if not is_valid and queue_duration > 0:
			addBeatsToSequence(instrument.copy(), queue_duration, ms, BEAT_MS, ROUND_TO_NEAREST)
			ms += queue_duration + READING_MS
			queue_duration = 0
		elif not is_valid:
			ms += READING_MS
		else:
			queue_duration += READING_MS
	if queue_duration > 0:
		addBeatsToSequence(instrument.copy(), queue_duration, ms, BEAT_MS, ROUND_TO_NEAREST)

# Sort sequence
sequence = sorted(sequence, key=lambda k: k['elapsed_ms'])

# Add milliseconds to sequence
elapsed = 0
for index, step in enumerate(sequence):
	sequence[index]['milliseconds'] = step['elapsed_ms'] - elapsed
	elapsed = step['elapsed_ms']

# Output total time with ending tail
elapsed_seconds = int(1.0*(elapsed+BEAT_MS)/1000)
print('Total sequence time: '+time.strftime('%M:%S', time.gmtime(elapsed_seconds)) + '(' + str(elapsed_seconds) + 's)')

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
		w.writerow(['Time', 'Date', 'Value', 'Residue', 'Normalized Value', 'Normalized Residue'])
		elapsed = 0
		for mindex, entry in enumerate(pm25):
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, entry['date'], entry['val'], entry['residue'], entry['nval'], entry['nresidue']])
			elapsed += READING_MS
		print('Successfully wrote summary file: '+REPORT_SUMMARY_OUTPUT_FILE)

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
	json_data = {
		'pm25_min': pm25_min,
		'pm25_max': pm25_max,
		'pm25_count': pm25_count,
		'total_ms': total_ms,
		'pm25_readings': pm25
	}
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(json_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
