# -*- coding: utf-8 -*-
##
# TRACK 6
# DISTANCE FROM HOME
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
DIVISIONS_PER_BEAT = 4 # e.g. 4 = quarter notes, 8 = eighth notes, etc
VARIANCE_MS = 20 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 1.0 # base gain
TEMPO = 1.0 # base tempo
MS_PER_YEAR = 4000
START_YEAR = 1975
STOP_YEAR = 2012

# Files
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
COUNTRIES_INPUT_FILE = 'data/countrycodes.json'
POPULATIONS_INPUT_FILE = 'data/populations.json'
REFUGEES_INPUT_FILE = 'data/refugees_processed.csv'
EVENTS_INPUT_FILE = 'data/events.csv'
SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
SUMMARY_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/years_refugees.json'
INSTRUMENTS_DIR = 'instruments/'

# Output options
WRITE_SEQUENCE = True
WRITE_REPORT = True
WRITE_VIS = False

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
ROUND_TO_NEAREST = round(BEAT_MS/DIVISIONS_PER_BEAT)
BEATS_PER_YEAR = round(MS_PER_YEAR/BEAT_MS)

countries = []
events = []
populations = []
world_populations = {}
refugees = []
years = []

instruments = []
sequence = []
hindex = 0

# Mean of list
def mean(data):
	if iter(data) is data:
		data = list(data)
	n = len(data)
	if n < 1:
		return 0
	else:
		return sum(data)/n

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
	for file,min_count,max_count,min_dist,max_dist,min_countries,max_countries,from_gain,to_gain,from_tempo,to_tempo,tempo_offset,interval_phase,interval,interval_offset,active in r:
		if int(active):
			index = len(instruments)
			# build instrument object
			_beat_ms = int(round(BEAT_MS/TEMPO))
			instrument = {
				'index': index,
				'file': INSTRUMENTS_DIR + file,
				'min_count': float(min_count),
				'max_count': float(max_count),
				'min_dist': float(min_dist),
				'max_dist': float(max_dist),
				'min_countries': float(min_countries),
				'max_countries': float(max_countries),
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

# Read countries from file
with open(COUNTRIES_INPUT_FILE) as data_file:
	countries = json.load(data_file)

# Read populations from file
with open(POPULATIONS_INPUT_FILE) as data_file:
	populations = json.load(data_file)
	world_populations = (p for p in populations if p['code'] == 'WLD').next()

# Read refugees from file
with open(REFUGEES_INPUT_FILE, 'rb') as f:
	lines = csv.reader(f, delimiter=',')
	next(lines, None) # remove header
	for origin,count,angle,origin_y,origin_x,year,asylum_x,asylum_y,asylum,distance in lines:
		year = int(year)
		if year >= START_YEAR and year <= STOP_YEAR:
			refugees.append({
				'origin': origin,
				'origin_name': (country['name'] for country in countries if country['code'] == origin).next(),
				'asylum': asylum,
				'count': int(count),
				'year': year,
				'origin_x': float(origin_x),
				'origin_y': float(origin_y),
				'asylum_x': float(asylum_x),
				'asylum_y': float(asylum_y),
				'distance': float(distance),
				'angle': float(angle)
			})

# Read events from file
with open(EVENTS_INPUT_FILE, 'rb') as f:
	lines = csv.reader(f, delimiter=',')
	next(lines, None) # remove header
	for code,year,headline,states in lines:
		events.append({
			'code': code,
			'name': (country['name'] for country in countries if country['code'] == code).next(),
			'year': int(year),
			'headline': headline,
			'states': states
		})

# Calc min/max
min_refugees = min([r['count'] for r in refugees])
max_refugees = max([r['count'] for r in refugees])
min_distance = min([r['distance'] for r in refugees])
max_distance = max([r['distance'] for r in refugees])
min_year = min([r['year'] for r in refugees])
max_year = max([r['year'] for r in refugees])

# Normalize data
for i,r in enumerate(refugees):
	refugees[i]['count_n'] = (1.0 * r['count'] - min_refugees) / (max_refugees - min_refugees)
	refugees[i]['distance_n'] = (1.0 * r['distance'] - min_distance) / (max_distance - min_distance)

# Report stats
print(str(max_year-min_year) + ' years: [' + str(min_year) + ',' + str(max_year) + ']')
print('Refugees range: [' + str(min_refugees) + ',' + str(max_refugees) + ']')

# Group by years
current_year = None
for r in refugees:
	if r['year'] != current_year:
		year = {
			'year': r['year'],
			'refugees': [r.copy()],
			'population': world_populations[str(r['year'])]
		}
		years.append(year)
		current_year = r['year']
	else:
		years[-1]['refugees'].append(r.copy())

# Process data
ms = 0
for i,y in enumerate(years):
	# Order refugees in each year
	years[i]['refugees'] = sorted(y['refugees'], key=lambda k: k['count'], reverse=True)
	years[i]['count'] = sum([r['count'] for r in y['refugees']])
	years[i]['avg_distance'] = mean([r['distance'] for r in y['refugees']])

	# Generate origin countries
	origin_codes = set([r['origin'] for r in y['refugees']])
	origin_countries = []
	for code in origin_codes:
		origin_refugees = [r for r in y['refugees'] if r['origin']==code]
		ref = origin_refugees[0]
		origin_countries.append({
			'code': code,
			'name': ref['origin_name'],
			'count': sum([r['count'] for r in origin_refugees]),
			'x': ref['origin_x'],
			'y': ref['origin_y'],
			'avg_distance': mean([r['distance'] for r in origin_refugees])
		})

	# Normalize distances
	years[i]['max_distance'] = max([r['distance'] for r in y['refugees']])
	for j,r in enumerate(y['refugees']):
		years[i]['refugees'][j]['year_distance_n'] = 1.0 * r['distance'] / years[i]['max_distance']

	# Sort country counts
	years[i]['countries'] = sorted(origin_countries, key=lambda k: k['count'], reverse=True)
	years[i]['events'] = [e for e in events if e['year']==y['year']]
	years[i]['countries_1000'] = len([c for c in origin_countries if c['count'] >= 1000])

	# Determine start/stop times
	years[i]['start_ms'] = ms
	years[i]['stop_ms'] = ms + MS_PER_YEAR
	ms += MS_PER_YEAR
	# print(str(y['year']) + ': ' + str(len(y['refugees'])) + ', ' + str(sum([r['count'] for r in y['refugees']])))

# Calculate total time
total_ms = max([y['stop_ms'] for y in years])
total_seconds = int(1.0*total_ms/1000)
print('Main sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + ' (' + str(total_seconds) + 's)')
print('Ms per beat: ' + str(BEAT_MS))
print('Beats per year: ' + str(BEATS_PER_YEAR))

# Normalize year/country counts
year_countries = [y['countries'] for y in years]
year_countries = [item for sublist in year_countries for item in sublist]
max_country_count = max([c['count'] for c in year_countries])
min_year_count = min([y['count'] for y in years])
max_year_count = max([y['count'] for y in years])
min_year_distance = min([y['avg_distance'] for y in years])
max_year_distance = max([y['avg_distance'] for y in years])
min_year_countries = min([y['countries_1000'] for y in years])
max_year_countries = max([y['countries_1000'] for y in years])
for i,y in enumerate(years):
	years[i]['count_n'] = (1.0 * y['count'] - min_year_count) / (max_year_count - min_year_count)
	years[i]['avg_distance_n'] = (1.0 * y['avg_distance'] - min_year_distance) / (max_year_distance - min_year_distance)
	years[i]['countries_1000_n'] = (1.0 * y['countries_1000'] - min_year_countries) / (max_year_countries - min_year_countries)
	for j,c in enumerate(y['countries']):
		years[i]['countries'][j]['count_n'] = 1.0 * c['count'] / max_country_count

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
def addBeatsToSequence(instrument, duration, ms, round_to, year):
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
				'elapsed_ms': max([elapsed_ms + variance, 0]),
				'duration': min([this_beat_ms, MS_PER_YEAR]),
				'year': year
			})
			hindex += 1
		remaining_duration -= this_beat_ms
		elapsed_duration += this_beat_ms
		ms += this_beat_ms

# Build sequence
for instrument in instruments:

	ms = None
	queue_duration = 0

	# Go through each year
	for year in years:

		is_valid = year['count_n'] >= instrument['min_count'] and year['count_n'] < instrument['max_count'] and year['avg_distance_n'] >= instrument['min_dist'] and year['avg_distance_n'] < instrument['max_dist'] and year['countries_1000_n'] >= instrument['min_countries'] and year['countries_1000_n'] < instrument['max_countries']

		# If note is valid, add it to sequence
		if not is_valid and queue_duration > 0 and ms != None or is_valid and ms != None and year['start_ms'] > (ms+queue_duration):
			addBeatsToSequence(instrument.copy(), queue_duration, ms, ROUND_TO_NEAREST, year['year'])
			ms = None
			queue_duration = 0

		if is_valid:
			if ms==None:
				ms = year['start_ms']
			queue_duration += (year['stop_ms'] - year['start_ms'])

	if queue_duration > 0 and ms != None:
		addBeatsToSequence(instrument.copy(), queue_duration, ms, ROUND_TO_NEAREST, years[-1]['year'])

# Sort sequence
sequence = sorted(sequence, key=lambda k: k['elapsed_ms'])

# Add milliseconds to sequence
elapsed = 0
for i, step in enumerate(sequence):
	sequence[i]['milliseconds'] = step['elapsed_ms'] - elapsed
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
	with open(SUMMARY_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		header = ['Time', 'Year', 'Count', 'Distance', 'Countries']
		w.writerow(header)
		for y in years:
			elapsed = y['start_ms']
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			row = [elapsed_f, y['year'], y['count_n'], y['avg_distance_n'], y['countries_1000_n']]
			w.writerow(row)
		print('Successfully wrote summary file: '+SUMMARY_OUTPUT_FILE)

	if len(sequence) > 0:
		with open(SUMMARY_SEQUENCE_OUTPUT_FILE, 'wb') as f:
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
			print('Successfully wrote sequence report to file: '+SUMMARY_SEQUENCE_OUTPUT_FILE)

# Build visualization data
vis_data = []
for y in years:
	year = {
		'y': y['year'],
		'ms0': y['start_ms'],
		'ms1': y['stop_ms'],
		'rc': "{:,}".format(y['count']),
		'p': "{:,}".format(y['population']),
		'cp': "{:,}".format(int(round(y['population']/y['count']))),
		'ct': "{:,}".format(int(y['countries_1000'])),
		'r': [],
		'c': [],
		'e': []
	}
	for c in y['countries']:
		year['c'].append({
			'n': c['name'],
			'cc': c['code'],
			'x': c['x'],
			'y': c['y'],
			'c': c['count'],
			'cn': c['count_n']
		})
	for e in y['events']:
		year['e'].append({
			'c': e['name'],
			'cc': e['code'],
			'h': e['headline']
		})
	year_instruments = [step for step in sequence if step['elapsed_ms']>=y['start_ms'] and step['elapsed_ms']<y['stop_ms']]
	year_instruments = sorted(year_instruments[:], key=lambda k: k['duration'])
	year_refugees = sorted(y['refugees'], key=lambda k: k['distance'])
	refugees_per_instrument = math.floor(1.0 * y['count'] / len(year_instruments))
	current_instrument_i = 0
	current_instrument = year_instruments[0]
	current_instrument_refugee_count = refugees_per_instrument
	for i,r in enumerate(year_refugees):
		current_refugee_count = r['count']
		while current_refugee_count > 0:
			add_count = min([current_refugee_count, current_instrument_refugee_count])
			year['r'].append({
				'ms0': current_instrument['elapsed_ms'],
				'ms1': current_instrument['elapsed_ms'] + current_instrument['duration'],
				'x1': r['origin_x'],
				'y1': r['origin_y'],
				'x2': r['asylum_x'],
				'y2': r['asylum_y'],
				'd': r['distance'],
				'dn': r['distance_n'],
				'c': add_count,
				'cn': r['count_n']
			})
			current_refugee_count -= add_count
			current_instrument_refugee_count -= add_count
			if current_instrument_refugee_count <= 0:
				current_instrument_i += 1
				if current_instrument_i >= len(year_instruments):
					current_instrument_i = len(year_instruments)-1
				current_instrument = year_instruments[current_instrument_i]
				current_instrument_refugee_count = refugees_per_instrument
	year['rms1'] = max([r['ms1'] for r in year['r']])
	vis_data.append(year)

if WRITE_VIS and len(vis_data)>0:
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(vis_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
