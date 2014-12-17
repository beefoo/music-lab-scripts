##
# TRACK 1
# One Train Two Tracks (datadrivendj.com/tracks/subway)
# Brian Foo (brianfoo.com)
# This file builds the sequence file for use with ChucK from the data supplied
##

# Library dependancies
import csv
import os
import random

# Config
BPM = 75
COUNTS_PER_BEAT = 8
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
INSTRUMENTS_DIR = 'instruments/'

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
COUNT_MS = round(1.0 * BEAT_MS / COUNTS_PER_BEAT)
BEATS = BPM * 2

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat) with '+str(COUNT_MS)+'ms per count')

# Initialize Variables
instruments = []
sequence = []

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,type,price,file in r:
		if file:
			instruments.append({
				'name': name.lower().replace(' ', '_'),
				'type': type.lower().replace(' ', '_'),
				'price': int(price),
				'file': INSTRUMENTS_DIR + file
			})

# Build sequence
ms = 0
for beat in range(BEATS):
	for count in range(COUNTS_PER_BEAT):
		coin = random.randint(0,3)
		instrument_index = random.randint(0,len(instruments)-1)
		if coin < 2:
			sequence.append({
				'instrument_index': instrument_index,
				'position': 0,
				'gain': 0.5,
				'rate': 1,
				'milliseconds': int(ms)
			})
			ms = 0
		else:
			ms += COUNT_MS

# Write instruments to file
with open(INSTRUMENTS_OUTPUT_FILE, 'wb') as f:
	w = csv.writer(f)	
	for index, instrument in enumerate(instruments):
		w.writerow([index])
		w.writerow([instrument['file']])
	f.seek(-2, os.SEEK_END) # remove newline
	f.truncate()
	print('Successfully wrote instruments to file.')

# Write sequence to file
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





