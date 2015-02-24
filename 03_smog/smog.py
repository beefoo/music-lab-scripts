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
READINGS_PER_BEAT = 4
DIVISIONS_PER_BEAT = 16 # e.g. 4 = quarter notes, 8 = eighth notes, etc
VARIANCE_MS = 10 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 1.0 # base gain
TEMPO = 1.0 # base tempo

# Files
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
PM25_INPUT_FILE = 'data/pm25_readings.csv'
REPORT_SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
REPORT_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/pm25_readings.json'
INSTRUMENTS_DIR = 'instruments/'

# Output options
WRITE_SEQUENCE = False
WRITE_REPORT = False
WRITE_JSON = False

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
	
# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,pm25_min,pm25_max,file,from_gain,to_gain,tempo,tempo_offset,interval_phase,interval,interval_offset,active in r:
		if int(active):
			index = len(instruments)
			# build instrument object
			instrument = {
				'index': index,
				'pm25_min': int(pm25_min),
				'pm25_max': int(pm25_max),
				'name': name,
				'file': INSTRUMENTS_DIR + file,
				'from_gain': float(from_gain),
				'to_gain': float(to_gain),
				'tempo': float(tempo),
				'tempo_offset': float(tempo_offset),
				'interval_ms': int(int(interval_phase)*BEAT_MS),
				'interval': int(interval),
				'interval_offset': int(interval_offset)
			}
			# add instrument to instruments
			instruments.append(instrument)

# Read PM2.5 from file
with open(PM25_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	pm25_min = int(next(r, None)[-1])
	pm25_max = int(next(r, None)[-1])
	pm25_count = int(next(r, None)[-1])
	if False:
		for _datetime, _value in r:
			datetime = time.strptime(_datetime, "%Y-%m-%d %H:%M") # 2009-01-01 00:00
			pm25.append({
				'datetime': _datetime,
				'value': int(_value)
			})

# Report PM2.5 data
print('Retrieved PM2.5 data with '+ str(pm25_count) + ' data points')
print('ug/m^3 range: ['+str(pm25_min)+','+str(pm25_max)+']')

# Calculate total time
total_beats = 1.0 * pm25_count / READINGS_PER_BEAT
total_ms = total_beats * BEAT_MS
total_seconds = int(1.0*total_ms/1000)
print('Total sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + '(' + str(total_seconds) + 's, '+str(total_beats)+' beats)')

# Sort sequence
# sequence = sorted(sequence, key=lambda k: k['elapsed_ms'])

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
		w.writerow(['Time', 'Value'])
		for mindex, entry in enumerate(pm25):
			elapsed = mindex * MEASURE_MS
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, entry['value']])
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
		'pm25_readings': pm25
	}
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(json_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
