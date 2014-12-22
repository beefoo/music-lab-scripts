##
# Script for trying out samples
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
BPM = 90
DIVISIONS_PER_BEAT = 8
METERS_PER_BEAT = 75
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
SUMMARY_OUTPUT_FILE = 'data/summary.csv'
INSTRUMENTS_DIR = 'instruments/'
WRITE_SEQUENCE = True
WRITE_SUMMARY = False
TOTAL_BEATS = 90

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
DIVISION_MS = round(1.0 * BEAT_MS / DIVISIONS_PER_BEAT)

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat) with '+str(DIVISION_MS)+'ms per division')

# Initialize Variables
instruments = []
sequence = []

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,type,file,gain,pattern,beats,active in r:
		if file and int(active):
			instruments.append({
				'name': name,
				'type': type.lower().replace(' ', '_'),
				'file': INSTRUMENTS_DIR + file,
				'gain': round(float(gain), 1),
				'pattern': [int(n) for n in pattern.split(',')],
				'beats': int(beats)
			})

# Determine if we should play this instrument at a particular beat/division
def canPlayInstrument(instrument, beat, division):
	pattern = instrument['pattern']
	beat_range = instrument['beats']
	valid_position = (beat % beat_range) * DIVISIONS_PER_BEAT + division
	canPlay = False
	for position in pattern:
		if position == valid_position:
			canPlay = True
			break
	return canPlay

# Build sequence
ms = 0
for beat in range(TOTAL_BEATS):
	for division in range(DIVISIONS_PER_BEAT):
		instrumentPlayed = False
		for index, instrument in enumerate(instruments):
			if canPlayInstrument(instrument, beat, division):
				my_ms = ms
				if my_ms > 0:
					my_ms += DIVISION_MS
				sequence.append({
					'instrument_index': index,
					'position': 0,
					'gain': instrument['gain'],
					'rate': 1,
					'milliseconds': int(my_ms)
				})
				instrumentPlayed = True
				ms = 0
		if 	not instrumentPlayed:
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
		w.writerow(['Instrument', 'Milliseconds'])		
		for step in sequence:
			w.writerow([instruments[step['instrument_index']]['name'], step['milliseconds']])
		print('Successfully wrote summary file.')
