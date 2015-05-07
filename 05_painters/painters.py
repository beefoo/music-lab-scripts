##
# TRACK 5
# LEE AND JACKSON
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
BPM = 60 # Beats per minute, e.g. 60, 75, 100, 120, 150
DIVISIONS_PER_BEAT = 16 # e.g. 4 = quarter notes, 8 = eighth notes, etc
PX_PER_BEAT = 40
VARIANCE_MS = 20 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 1.0 # base gain
TEMPO = 1.0 # base tempo

# Files
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
EVENTS_INPUT_FILE = 'data/events.csv'
PAINTING_SAMPLES_INPUT_FILE = 'data/painting_samples.csv'
REPORT_SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
REPORT_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/paintings.json'
INSTRUMENTS_DIR = 'instruments/'

# Output options
WRITE_SEQUENCE = False
WRITE_REPORT = False
WRITE_JSON = False

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
ROUND_TO_NEAREST = round(BEAT_MS/DIVISIONS_PER_BEAT)
PX_PER_MS = PX_PER_BEAT / BEAT_MS

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat)')

# Initialize Variables
instruments = []
paintings = []
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

# Find index of first item that matches value
def findInList(list, key, value):
	found = -1
	for index, item in enumerate(list):
		if item[key] == value:
			found = index
			break
	return found

# Mean of list
def mean(data, key):
    n = len(data)
    if n < 1:
		return 0
    else:
		list = [i[key] for i in data]
		return sum(list)/n
	
# round {n} to nearest {nearest}
def roundToNearest(n, nearest):
	return 1.0 * round(1.0*n/nearest) * nearest

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	for file,gain,tempo,tempo_offset,interval_phase,interval,interval_offset,active in r:
		if int(active):
			index = len(instruments)
			# build instrument object
			_beat_ms = int(round(BEAT_MS/(float(tempo)*TEMPO)))
			instrument = {
				'file': INSTRUMENTS_DIR + file,
				'index': index,
				'gain': float(gain) * GAIN,
				'to_tempo': float(tempo) * TEMPO,
				'tempo_offset': float(tempo_offset),
				'interval_ms': int(int(interval_phase)*_beat_ms),
				'interval': int(interval),
				'interval_offset': int(interval_offset),
				'beat_ms': _beat_ms
			}
			# add instrument to instruments
			instruments.append(instrument)

# Read pairs from file
max_area = None
min_area = None
max_sat = None
min_sat = None
max_bri = None
min_bri = None
min_year = None
max_year = None
with open(PAINTING_SAMPLES_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	current_file = None
	for _title,_artist,_position,_year,_file,_painting_width,_painting_height,_year_start_ms,_year_stop_ms,_hue,_saturation,_brightness,_x,_y,_width,_height in r:
		_area = int(_width) * int(_height)
		
		# Init min/max
		min_area = _area if min_area is None else min_area
		max_area = _area if max_area is None else max_area
		min_sat = int(_saturation) if min_sat is None else min_sat
		max_sat = int(_saturation) if max_sat is None else max_sat
		min_bri = int(_brightness) if min_bri is None else min_bri
		max_bri = int(_brightness) if max_bri is None else max_bri
		min_year = int(_year) if min_year is None else min_year
		max_year = int(_year) if max_year is None else max_year
		
		# Calc min/max
		min_area = min([min_area, _area])
		max_area = max([max_area, _area])
		min_sat = min([min_sat, int(_saturation)])
		max_sat = max([max_sat, int(_saturation)])
		min_bri = min([min_bri, int(_brightness)])
		max_bri = max([max_bri, int(_brightness)])
		min_year = min([min_year, int(_year)])
		max_year = max([max_year, int(_year)])
		
		# Init sample
		sample = {
			'hue': int(_hue),
			'saturation': int(_saturation),
			'brightness': int(_brightness),
			'x': int(_x),
			'y': int(_y),
			'width': int(_width),
			'height': int(_height),
			'area': _area
		}
		
		# Add painting to list
		if current_file != _file:
			index = len(paintings)
			duration = 1.0 * int(_painting_width) / PX_PER_MS
			paintings.append({
				'index': index,
				'title': _title,
				'artist': _artist,
				'position': int(_position),
				'year': int(_year),
				'file': _file,
				'width': int(_painting_width),
				'height': int(_painting_height),
				'start_ms': int(_year_start_ms),
				'stop_ms': int(_year_start_ms) + duration,
				'samples': [sample]
			})
			current_file = _file
			
		# Append sample to current painting
		else:
			paintings[-1]['samples'].append(sample)

# Report painting data
print('Retrieved painting data with '+ str(len(paintings)) + ' paintings and '+ str(sum(len(p['samples']) for p in paintings)) +' samples')
print('Sample area range: ['+str(min_area)+','+str(max_area)+']')
print('Sample saturation range: ['+str(min_sat)+','+str(max_sat)+']')
print('Sample brightness range: ['+str(min_bri)+','+str(max_bri)+']')
print('Year range: ['+str(min_year)+','+str(max_year)+']')

# Calculate total time
total_ms = max([p['stop_ms'] for p in paintings])
total_seconds = int(1.0*total_ms/1000)
print('Main sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + ' (' + str(total_seconds) + 's)')
print(str(PX_PER_BEAT)+'px per beat')

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
	offset_ms = int(instrument['tempo_offset'] * instrument['beat_ms'])
	ms += offset_ms
	remaining_duration = int(duration)
	elapsed_duration = offset_ms
	while remaining_duration > 0:
		elapsed_ms = int(ms)
		percent_complete = 1.0 * elapsed_duration / duration
		this_beat_ms = instrument['beat_ms']
		# add to sequence if in valid interval
		if isValidInterval(instrument, elapsed_ms):
			h = halton(hindex, 3)
			variance = int(h * VARIANCE_MS * 2 - VARIANCE_MS)
			sequence.append({
				'instrument_index': instrument['index'],
				'instrument': instrument,
				'position': 0,
				'rate': 1,
				'gain': instrument['gain'],
				'elapsed_ms': max([elapsed_ms + variance, 0])
			})
			hindex += 1
		remaining_duration -= this_beat_ms
		elapsed_duration += this_beat_ms
		ms += this_beat_ms

# Build sequence


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
		w.writerow(['Time', 'Title', 'File'])
		for painting in paintings:
			elapsed = painting['start_ms']
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, painting['title'], painting['file']])
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
		'paintings': []
	}
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(json_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
