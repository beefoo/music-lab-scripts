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

# Config
BPM = 75
DIVISIONS_PER_BEAT = 8
METERS_PER_BEAT = 75
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
STATIONS_INPUT_FILE = 'data/stations.csv'
SUMMARY_OUTPUT_FILE = 'data/ck_summary.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
INSTRUMENTS_DIR = 'instruments/'
SEQUENCE_MODE = 'random' # options: random, fixed
WRITE_SEQUENCE = True
WRITE_SUMMARY = True

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
DIVISION_MS = round(1.0 * BEAT_MS / DIVISIONS_PER_BEAT)

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat) with '+str(DIVISION_MS)+'ms per division')

# Initialize Variables
instruments = []
stations = []
sequence = []

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,type,price,file,gain,borough,positions,beats,active in r:
		if file and int(active):
			instruments.append({
				'name': name,
				'type': type.lower().replace(' ', '_'),
				'price': int(price),
				'file': INSTRUMENTS_DIR + file,
				'gain': round(float(gain), 1),
				'borough': borough.lower(),
				'positions': [int(n) for n in positions.split(',')],
				'beats': int(beats)
			})			

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
	
def getInstrumentIndex(name):
	return next((index for index, instrument in enumerate(instruments) if instrument['name'] == name), 0)

# Buy instruments based on a specified budget
def buyInstruments(budget):
	instruments_cart = []
	instruments_shelf = instruments[:]
	count = 0
	while(len(instruments_shelf) > 0 and budget > 0):
		for idx, i in enumerate(instruments_shelf):
			# Alternate percussion and non-percussion instruments
			if count % 2 == 0:
				if i['type'] != 'percussion' and i['price'] < budget:
					budget -= i['price']
					new_instrument = instruments_shelf.pop(idx)
					new_instrument['idx'] = getInstrumentIndex(new_instrument['name'])
					instruments_cart.append(new_instrument)
					break
				elif i['type'] != 'percussion':
					instruments_shelf.pop(idx)
			else:
				if i['type'] == 'percussion' and i['price'] < budget:
					budget -= i['price']
					new_instrument = instruments_shelf.pop(idx)
					new_instrument['idx'] = getInstrumentIndex(new_instrument['name'])
					instruments_cart.append(new_instrument)
					break
				elif i['type'] == 'percussion':
					instruments_shelf.pop(idx)
		count += 1
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
minutes = round(1.0*total_beats/BPM, 2)
station_count = len(stations)-1
print('Total distance in meters: '+str(round(total_distance)))
print('Distance range in meters: ['+str(min_distance)+','+str(max_distance)+']')
print('Total beats: '+str(total_beats)+' ('+str(minutes)+' minutes)')
print('Average beats per station: '+(str(1.0*total_beats/station_count))+' ('+(str(1.0*minutes/station_count*60))+' seconds)')

# Determine if we should play this instrument at a particular beat/division
def canPlayInstrument(instrument, beat, division):
	positions = instrument['positions']
	beat_range = instrument['beats']
	valid_position = (beat % beat_range) * DIVISIONS_PER_BEAT + division
	canPlay = False
	for position in positions:
		if position == valid_position:
			canPlay = True
			break
	return canPlay

# Build sequence
ms = 0
for index, station in enumerate(stations):
	for beat in range(station['beats']):
		for division in range(DIVISIONS_PER_BEAT):
			instrumentPlayed = False
			for instrument in station['instruments']:
				if canPlayInstrument(instrument, beat, division):
					sequence.append({
						'instrument_index': instrument['idx'],
						'position': 0,
						'gain': instrument['gain'],
						'rate': 1,
						'milliseconds': int(ms)
					})
					instrumentPlayed = True
			if 	instrumentPlayed:
				ms = 0
			else:
				ms += DIVISION_MS

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

