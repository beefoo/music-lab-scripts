##
# TRACK 1
# One Train Two Tracks (datadrivendj.com/tracks/subway)
# Brian Foo (brianfoo.com)
# This file builds the sequence file for use with ChucK from the data supplied
##

# Library dependancies
import csv
import math
import os
import random
import re
import time

# Config
BPM_MIN = 60
BPM_MAX = 110
DIVISIONS_PER_BEAT = 4
METERS_PER_BEAT = 50
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
STATIONS_INPUT_FILE = 'data/stations.csv'
SUMMARY_OUTPUT_FILE = 'data/ck_summary.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
INSTRUMENTS_DIR = 'instruments/'
WRITE_SEQUENCE = True
WRITE_SUMMARY = True

# Calculations
AVG_BPM = 0.5 * (BPM_MAX - BPM_MIN)
MIN_BEAT_MS = round(60.0 / BPM_MAX * 1000)
MAX_BEAT_MS = round(60.0 / BPM_MIN * 1000)

print('Building sequence at '+str(BPM_MIN)+'-'+str(BPM_MAX)+' BPM ('+str(MIN_BEAT_MS)+'-'+str(MAX_BEAT_MS)+'ms per beat)')

# Initialize Variables
instruments = []
instrument_groups = []
instrument_price_groups = []
stations = []
sequence = []
hindex = 0

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

# Add item to list given key, value
def addToList(list, key, value, items_key, item):
	index = findInList(list, key, value)
	if index >= 0:
		list[index][items_key].append(item)
	else:
		index = len(list)
		new_item = {}
		new_item[key] = value
		new_item[items_key] = [item]
		list.append(new_item)
	return list[index]

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,type,price,file,gain,borough,pattern1,pattern2,pattern3,beats,active in r:
		if file and int(active):
			group_name = name.lower().replace(' ', '_')
			index = len(instruments)
			# determine valid patterns
			patterns = [
				[int(n) for n in pattern1.split(',')],
				[int(n) for n in pattern2.split(',')],
				[int(n) for n in pattern3.split(',')]
			]
			valid_patterns = []
			for pattern in patterns:
				if len(pattern) > 0 and pattern[0] >= 0:
					valid_patterns.append(pattern)
			# add instrument to instruments, groups, and prices
			instrument = {
				'index': index,
				'group': group_name,
				'name': name,
				'type': type.lower().replace(' ', '_'),
				'price': int(price),
				'file': INSTRUMENTS_DIR + file,
				'gain': round(float(gain), 1),
				'borough': borough.lower(),
				'patterns': valid_patterns,
				'beats': int(beats)
			}
			instruments.append(instrument)
			group = addToList(instrument_groups, 'name', instrument['group'], 'instruments', instrument)
			if len(group['instruments']) <= 1:
				price_group = addToList(instrument_price_groups, 'price', instrument['price'], 'instrument_groups', group)

# Read stations from file
with open(STATIONS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,income_annual,income,lat,lng,borough in r:
		stations.append({
			'name': name,
			'budget': float(re.sub(r'[\$|,]', '', income)),
			'lat': float(lat),
			'lng': float(lng),
			'beats': 0,
			'distance': 0,
			'borough': borough.lower(),			
			'instruments': []
		})

# For calculating distance between two coords(lat, lng)
def distBetweenCoords(lat1, lng1, lat2, lng2):
	earthRadius = 6371000 # meters
	dLat = math.radians(lat2-lat1)
	dLng = math.radians(lng2-lng1)
	a = math.sin(dLat/2) * math.sin(dLat/2) + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dLng/2) * math.sin(dLng/2)
	c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
	dist = float(earthRadius * c)
	return dist

# Choose instrument group from a list of groups
def chooseInstrumentGroup(hindex, groups):
	l = len(groups)
	h = halton(hindex, 3)
	index = int(math.floor(h*l))
	return groups[index]

# Buy instruments based on a specified budget
def buyInstruments(budget):
	global hindex
	instruments_cart = []
	instruments_shelf = instrument_price_groups[:]
	while(len(instruments_shelf) > 0 and budget > 0):
		for idx, i in enumerate(instruments_shelf):
			instrument_price_group = instruments_shelf.pop(idx)
			instrument_group = chooseInstrumentGroup(hindex, instrument_price_group['instrument_groups'])
			hindex += 1
			if i['price'] < budget:
				budget -= i['price']			
				instruments_cart.append(instrument_group)
				break
	return instruments_cart

# Pre-process stations
min_distance = 0
max_distance = 0
total_distance = 0
total_beats = 0
for index, station in enumerate(stations):
	# determine the station's budget
	stations[index]['instruments'] = buyInstruments(station['budget'])
	if index > 0:
		# determine distance between last station
		distance = distBetweenCoords(station['lat'], station['lng'], stations[index-1]['lat'], stations[index-1]['lng'])
		beats = int(round(distance / METERS_PER_BEAT))
		stations[index-1]['distance'] = distance
		stations[index-1]['beats'] = beats	
		total_distance += distance
		total_beats += beats
		if distance > max_distance:
			max_distance = distance
		if distance < min_distance or min_distance == 0:
			min_distance = distance

# Calculate how many beats
minutes = round(1.0*total_beats/AVG_BPM, 2)
station_count = len(stations)-1
print('Total distance in meters: '+str(round(total_distance)))
print('Distance range in meters: ['+str(min_distance)+','+str(max_distance)+']')
print('Total beats: '+str(total_beats))
print('Average beats per station: '+str(1.0*total_beats/station_count))

# Choose pattern from a list of patterns
def choosePattern(hindex, patterns):
	l = len(patterns)
	h = halton(hindex, 3)
	index = int(math.floor(h*l))
	return patterns[index]

# Determine if we should play this instrument at a particular beat/division
def canPlayInstrument(instrument, beat, division, hindex):
	pattern = choosePattern(hindex, instrument['patterns'])
	beat_range = instrument['beats']
	valid_position = (beat % beat_range) * DIVISIONS_PER_BEAT + division
	canPlay = False
	for position in pattern:
		if position == valid_position:
			canPlay = True
			break
	return canPlay

def getMS(beat, division, total_beats, divisions_per_beat, min_ms, max_ms):
	total_divisions = total_beats * divisions_per_beat
	current_division = beat * divisions_per_beat + division
	percent_complete = 1.0 * current_division / total_divisions
	multiplier = abs(0.5 - percent_complete) * 2.0
	min = 1.0 * min_ms / divisions_per_beat
	max = 1.0 * max_ms / divisions_per_beat
	ms = multiplier * (max - min) + min
	return ms

# Build sequence
total_ms = 0
ms = 0
hindex = 0
# Each station
for index, station in enumerate(stations):
	# Each beat in station
	for beat in range(station['beats']):
		# Each division in beat
		for division in range(DIVISIONS_PER_BEAT):
			# Each instrument group in station
			for instrument_group in station['instruments']:
				# Each instrument in group
				for instrument in instrument_group['instruments']:
					if canPlayInstrument(instrument, beat, division, hindex):
						sequence.append({
							'instrument_index': instrument['index'],
							'position': 0,
							'gain': instrument['gain'],
							'rate': 1,
							'milliseconds': int(ms)
						})
						ms = 0
					hindex += 1
			inc = getMS(beat, division, station['beats'], DIVISIONS_PER_BEAT, MIN_BEAT_MS, MAX_BEAT_MS)
			ms += inc
			total_ms += inc

total_seconds = int(1.0*total_ms/1000)
seconds_per_station = int(1.0*total_seconds/station_count)
print('Total time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + '(' + str(total_seconds) + 's)')
print('Average time per station: '+time.strftime('%M:%S', time.gmtime(seconds_per_station)))
			
# Write instruments to file
if WRITE_SEQUENCE:
	with open(INSTRUMENTS_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)	
		for index, instrument in enumerate(instruments):
			w.writerow([index])
			w.writerow([instrument['file']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote instruments to file.')

# Write sequence to file
if WRITE_SEQUENCE:
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
		print('Successfully wrote sequence to file.')

# Write summary file
if WRITE_SUMMARY:
	with open(SUMMARY_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(['Name', 'Distance', 'Beats', 'Instruments'])		
		for station in stations:
			w.writerow([station['name'], station['distance'], station['beats'], ' '.join([i['name'] for i in station['instruments']])])
		print('Successfully wrote summary file.')

