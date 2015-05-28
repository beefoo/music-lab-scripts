##
# TRACK 6
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
DIVISIONS_PER_BEAT = 4 # e.g. 4 = quarter notes, 8 = eighth notes, etc
PX_PER_BEAT = 40
VARIANCE_MS = 20 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 1.0 # base gain
TEMPO = 1.0 # base tempo
PERCENT_TOTAL_NOTE_THRESHOLD = 0.16
BRIGHTNESS_THRESHOLD = 20
SATURATION_THRESHOLD = 20

# Files
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
SYNESTHESIA_INPUT_FILE = 'data/synesthesia.csv'
EVENTS_INPUT_FILE = 'data/events.csv'
PAINTING_SAMPLES_INPUT_FILE = 'data/painting_samples.csv'
REPORT_SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
REPORT_NOTES_OUTPUT_FILE = 'data/report_summary_notes.csv'
REPORT_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/paintings.json'
INSTRUMENTS_DIR = 'instruments/'

# Output options
WRITE_SEQUENCE = True
WRITE_REPORT = True
WRITE_JSON = False

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
ROUND_TO_NEAREST = round(BEAT_MS/DIVISIONS_PER_BEAT)
PX_PER_MS = PX_PER_BEAT / BEAT_MS

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat)')

# Initialize Variables
instruments = []
paintings = []
events = []
synesthesia = []
notes = []
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
def mean(data):
    if iter(data) is data:
		data = list(data)
    n = len(data)
    if n < 1:
		return 0
    else:
		return sum(data)/n

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

# floor {n} to nearest {nearest}
def floorToNearest(n, nearest):
	return 1.0 * math.floor(1.0*n/nearest) * nearest

# round {n} to nearest {nearest}
def roundToNearest(n, nearest):
	return 1.0 * round(1.0*n/nearest) * nearest
	
# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	for file,artist,size_min,size_max,bri_min,bri_max,var_min,var_max,year_min,year_max,note,from_gain,to_gain,from_tempo,to_tempo,tempo_offset,interval_phase,interval,interval_offset,active in r:
		if int(active):
			index = len(instruments)
			# build instrument object
			_beat_ms = int(round(BEAT_MS/TEMPO))
			instrument = {
				'index': index,
				'file': INSTRUMENTS_DIR + file,
				'artist': artist,
				'size_min': float(size_min),
				'size_max': float(size_max),
				'bri_min': float(bri_min),
				'bri_max': float(bri_max),
				'var_min': float(var_min),
				'var_max': float(var_max),
				'year_min': int(year_min),
				'year_max': int(year_max),
				'note': note,
				'from_gain': float(from_gain) * GAIN,
				'to_gain': float(to_gain) * GAIN,
				'from_tempo': float(from_tempo) * TEMPO,
				'to_tempo': float(to_tempo) * TEMPO,
				'tempo_offset': float(tempo_offset),
				'interval_ms': int(int(interval_phase)*_beat_ms),
				'interval': int(interval),
				'interval_offset': int(interval_offset),
				'from_beat_ms': int(round(BEAT_MS/(float(from_tempo)*TEMPO))),
				'to_beat_ms': int(round(BEAT_MS/(float(to_tempo)*TEMPO))),
				'beat_ms': _beat_ms
			}
			# add instrument to instruments
			instruments.append(instrument)

# Read synesthesia from file
with open(SYNESTHESIA_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	for _hue, _saturation, _color, _note in r:
		synesthesia.append({
			'hue': int(_hue),
			'saturation': int(_saturation),
			'color': _color,
			'note': _note
		})
	notes = set([s["note"] for s in synesthesia])

# Distance function
def distance(x1, y1, x2, y2):
    sq1 = 1.0*(x1-x2)*(x1-x2)
    sq2 = 1.0*(y1-y2)*(y1-y2)
    return math.sqrt(sq1 + sq2)

# Retrieves a note based on hue and saturation
def getNote(hue, saturation):
	note = synesthesia[0]['note']
	minDistance = None
	for s in synesthesia:
		d = distance(hue, saturation, s['hue'], s['saturation'])
		# d = abs(hue-s['hue'])
		if minDistance is None or d < minDistance:
			minDistance = d
			note = s['note']
	return note	

# Read paintings from file
min_year = None
max_year = None
with open(PAINTING_SAMPLES_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	current_file = None
	for _title,_artist,_position,_year,_file,_painting_width,_painting_height,_year_start_ms,_year_stop_ms,_hue,_saturation,_brightness,_x,_y,_width,_height in r:
		_area = int(_width) * int(_height)
		
		# Calc min/max
		min_year = int(_year) if min_year is None else min_year
		max_year = int(_year) if max_year is None else max_year
		min_year = min([min_year, int(_year)])
		max_year = max([max_year, int(_year)])
		
		# Retrieve note
		note = getNote(int(_hue), int(_saturation))
		
		# Init sample
		sample = {
			'hue': int(_hue),
			'saturation': int(_saturation),
			'brightness': int(_brightness),
			'x': int(_x),
			'y': int(_y),
			'width': int(_width),
			'height': int(_height),
			'area': _area,
			'note': note
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
				'samples': [sample],
				'notes': [
					{'note': note, 'areas': [_area], 'brightnesses': [int(_brightness)]}
				]
			})
			current_file = _file
			
		# Append sample to current painting
		else:
			paintings[-1]['samples'].append(sample)
			note_i = findInList(paintings[-1]['notes'], 'note', note)
			if note_i >= 0:
				paintings[-1]['notes'][note_i]['areas'].append(_area)
				paintings[-1]['notes'][note_i]['brightnesses'].append(int(_brightness))
			else:
				paintings[-1]['notes'].append({'note': note, 'areas': [_area], 'brightnesses': [int(_brightness)]})

# Aggregate, normalize, sort data
max_area_mean = None
min_area_mean = None
for pi, painting in enumerate(paintings):
	
	sample_count = len(painting['samples'])
	paintings[pi]['sample_count'] = sample_count

	# Calculate count/sum/mean note size and brightness
	for ni, note in enumerate(painting['notes']):
		# Calc area
		area_count = len(note['areas'])
		area_sum = sum(note['areas'])
		area_mean = 1.0 * area_sum / area_count
		paintings[pi]['notes'][ni]['count_area'] = area_count
		paintings[pi]['notes'][ni]['total_area'] = area_sum
		paintings[pi]['notes'][ni]['mean_area'] = area_mean
		
		# Calc brightness
		brightness_count = len(note['brightnesses'])
		brightness_sum = sum(note['brightnesses'])
		brightness_mean = 1.0 * brightness_sum / brightness_count
		paintings[pi]['notes'][ni]['count_brightness'] = brightness_count
		paintings[pi]['notes'][ni]['total_brightness'] = brightness_sum
		paintings[pi]['notes'][ni]['mean_brightness'] = brightness_mean
		
		# Percent of total painting samples
		paintings[pi]['notes'][ni]['percent_total'] = 1.0 * area_count / sample_count
		
		# Calc min/max
		min_area_mean = area_mean if min_area_mean is None else min_area_mean
		max_area_mean = area_mean if max_area_mean is None else max_area_mean
		min_area_mean = min([min_area_mean, area_mean])
		max_area_mean = max([max_area_mean, area_mean])
		
	# Painting calculations
	psamples = paintings[pi]['samples']
	psamples_len = len(psamples)
	mean_brightness = 1.0 * sum([sample['brightness'] for sample in psamples]) / psamples_len
	mean_area = 1.0 * sum([sample['area'] for sample in psamples]) / psamples_len
	variance_hue = 1.0 * variance([sample['hue'] for sample in psamples if sample['saturation'] > SATURATION_THRESHOLD and sample['brightness'] > BRIGHTNESS_THRESHOLD])
	paintings[pi]['mean_brightness'] = mean_brightness
	paintings[pi]['mean_area'] = mean_area
	paintings[pi]['variance_hue'] = variance_hue
	
	# Determine primary note
	sorted_notes = sorted(paintings[pi]['notes'], key=lambda k: k['percent_total'])
	paintings[pi]['primary_note'] = sorted_notes[-1]
	
# Calc min/max
p_min_brightness_mean = min([painting['mean_brightness'] for painting in paintings])
p_max_brightness_mean = max([painting['mean_brightness'] for painting in paintings])
p_min_area_mean = min([painting['mean_area'] for painting in paintings])
p_max_area_mean = max([painting['mean_area'] for painting in paintings])
p_min_variance_hue = min([painting['variance_hue'] for painting in paintings])
p_max_variance_hue = max([painting['variance_hue'] for painting in paintings])	

# Normalize values
for pi, painting in enumerate(paintings):
	paintings[pi]['mean_brightness_i'] = (1.0 * painting['mean_brightness'] - p_min_brightness_mean) / (p_max_brightness_mean - p_min_brightness_mean) * 100
	paintings[pi]['mean_area_i'] = (1.0 * painting['mean_area'] - p_min_area_mean) / (p_max_area_mean - p_min_area_mean) * 100
	paintings[pi]['variance_hue_i'] = (1.0 * painting['variance_hue'] - p_min_variance_hue) / (p_max_variance_hue - p_min_variance_hue) * 100
	for ni, note in enumerate(painting['notes']):
		paintings[pi]['notes'][ni]['mean_area_i'] = (1.0 * note['mean_area'] - min_area_mean) / (max_area_mean - min_area_mean) * 100

# Report painting data
print('Retrieved painting data with '+ str(len(paintings)) + ' paintings and '+ str(sum(len(p['samples']) for p in paintings)) +' samples')
print('Sample area range: ['+str(min_area_mean)+','+str(max_area_mean)+']')
print('Year range: ['+str(min_year)+','+str(max_year)+']')

# Calculate total time
total_ms = max([p['stop_ms'] for p in paintings])
total_seconds = int(1.0*total_ms/1000)
print('Main sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + ' (' + str(total_seconds) + 's)')
print(str(PX_PER_BEAT)+'px per beat')

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
	multiplier = getMultiplier(percent_complete)
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
def addBeatsToSequence(instrument, duration, ms, round_to):
	global sequence
	global hindex
	beat_ms = int(roundToNearest(instrument['beat_ms'], round_to))
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

# Build sequence
for instrument in instruments:
	
	ms = None
	queue_duration = 0
	
	# Go through each painting
	for painting in paintings:
	
		is_valid = (painting['artist']==instrument['artist'] or instrument['artist']=='any') and (instrument['note']==painting['primary_note']['note'] or instrument['note']=='any') and painting['mean_area_i'] >= instrument['size_min'] and painting['mean_area_i'] < instrument['size_max'] and painting['mean_brightness_i'] >= instrument['bri_min'] and painting['mean_brightness_i'] < instrument['bri_max'] and painting['variance_hue_i'] >= instrument['var_min'] and painting['variance_hue_i'] < instrument['var_max'] and painting['year'] >= instrument['year_min'] and painting['year'] <= instrument['year_max']
		
		# If note is valid, add it to sequence
		if not is_valid and queue_duration > 0 and ms != None or is_valid and ms != None and painting['start_ms'] > (ms+queue_duration):
			addBeatsToSequence(instrument.copy(), queue_duration, ms, ROUND_TO_NEAREST)
			ms = None
			queue_duration = 0
			
		if is_valid:			
			if ms==None:
				ms = painting['start_ms']	
			queue_duration += (painting['stop_ms'] - painting['start_ms'])
	
	if queue_duration > 0 and ms != None:
		addBeatsToSequence(instrument.copy(), queue_duration, ms, ROUND_TO_NEAREST)

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

	# Notes report
	with open(REPORT_NOTES_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		header = ['Time', 'Title', 'File']
		header.extend(notes)
		w.writerow(header)
		for painting in paintings:
			elapsed = painting['start_ms']
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			row = [elapsed_f, painting['title'], painting['file']]
			for note in notes:
				note_i = findInList(painting['notes'], 'note', note)
				if note_i >= 0:
					# row.append(painting['notes'][note_i]['total_area'])
					row.append(round(painting['notes'][note_i]['percent_total']*100, 10))
				else:
					row.append(0)
			w.writerow(row)
		print('Successfully wrote summary file: '+REPORT_NOTES_OUTPUT_FILE)
	
	# Paintings report
	with open(REPORT_SUMMARY_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		artists = set([p['artist'] for p in paintings])
		years = set([p['year'] for p in paintings])
		header = ['Time', 'Year']
		for artist in artists:
			header.append(artist + ' Mean Brightness')
			header.append(artist + ' Mean Area')
			header.append(artist + ' Hue Variance')
		w.writerow(header)
		for year in years:
			y_paintings = [p for p in paintings if p['year'] == year]		
			elapsed = y_paintings[0]['start_ms']
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			row = [elapsed_f, year]
			for artist in artists:
				a_paintings = [p for p in y_paintings if p['artist'] == artist]
				if len(a_paintings) > 0:
					p = a_paintings[0]
					row.extend([p['mean_brightness_i'], p['mean_area_i'], p['variance_hue_i']])
				else:
					row.extend(['','',''])
			w.writerow(row)
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
