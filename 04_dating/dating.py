##
# TRACK 4
# CALL & RESPONSE
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
BEATS_PER_PAIR = 4
VARIANCE_MS = 10 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 0.4 # base gain
TEMPO = 1.0 # base tempo

# Files
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
PAIRS_INPUT_FILE = 'data/pairs.csv'
REPORT_SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
REPORT_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/pairs.json'
INSTRUMENTS_DIR = 'instruments/'

# Output options
WRITE_SEQUENCE = False
WRITE_REPORT = False
WRITE_JSON = True

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
ROUND_TO_NEAREST = round(BEAT_MS/DIVISIONS_PER_BEAT)

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat)')

# Initialize Variables
instruments = []
pairs = []
sequence = []
hindex = 0
total_ms = 0
min_percent = None
max_percent = None

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

# Read pairs from file
with open(PAIRS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	for _order, _f_race, _m_race, _f_percent, _m_percent, _year in r:
		if min_percent is None:
			min_percent = int(_f_percent)
		if max_percent is None:
			max_percent = int(_f_percent)
		min_percent = min([min_percent, int(_f_percent), int(_m_percent)])
		max_percent = max([max_percent, int(_f_percent), int(_m_percent)])
		pairs.append({
			'f_race': _f_race,
			'm_race': _m_race,
			'f_percent': int(_f_percent),
			'm_percent': int(_m_percent),
			'year': int(_year)
		})

# Report PM2.5 data
print('Retrieved pairs data with '+ str(len(pairs)) + ' data points')
print('Pecent range: ['+str(min_percent)+','+str(max_percent)+']')

# Calculate total time
total_beats = 1.0 * len(pairs) * BEATS_PER_PAIR
total_ms = total_beats * BEAT_MS
total_seconds = int(1.0*total_ms/1000)
PAIR_MS = total_ms / len(pairs)
print('Main sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + ' (' + str(total_seconds) + 's, '+str(total_beats)+' beats)')
print(str(PAIR_MS)+'ms per pair')

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
		w.writerow(['Time', 'Year', 'F Race', 'M Race', 'F Percent', 'M Percent'])
		elapsed = 0
		for pair in pairs:
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, pair['year'], pair['f_race'], pair['m_race'], pair['f_percent'], pair['m_percent']])
			elapsed += PAIR_MS
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
	elapsed = 0
	for pindex, pair in enumerate(pairs):
		pairs[pindex]['start_ms'] = elapsed
		pairs[pindex]['stop_ms'] = elapsed + PAIR_MS
		elapsed += PAIR_MS
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(pairs, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
