##
# TRACK 2
# RHAPSODY IN GREY (datadrivendj.com/tracks/brain)
# Brian Foo (brianfoo.com)
# This file builds the sequence file for use with ChucK from the data supplied
##

# Library dependancies
import csv
import json
import math
import os
import random
import re
import time

# Config
BPM = 75 # Beats per minute, e.g. 60, 75, 100, 120, 150
DIVISIONS_PER_BEAT = 16 # e.g. 4 = quarter notes, 8 = eighth notes, etc
VARIANCE_MS = 10 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
PRECISION = 6
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
EEG_INPUT_FILE = 'data/eeg.csv'
REPORT_SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
REPORT_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/eeg.json'
INSTRUMENTS_DIR = 'instruments/'
WRITE_SEQUENCE = False
WRITE_REPORT = False
WRITE_JSON = True
LABELS = ['Time', 'FP1-F7', 'F7-T7', 'T7-P7', 'P7-O1', 'FP1-F3', 'F3-C3', 'C3-P3', 'P3-O1', 'FP2-F4', 'F4-C4', 'C4-P4', 'P4-O2', 'FP2-F8', 'F8-T8', 'T8-P8', 'P8-O2', 'FZ-CZ', 'CZ-PZ', 'P7-T7', 'T7-FT9', 'FT9-FT10', 'FT10-T8', 'T8-P8']

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
ROUND_TO_NEAREST = round(BEAT_MS/DIVISIONS_PER_BEAT)

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat)')

# Initialize Variables
instruments = []
eeg = []
eeg_min = []
eeg_max = []
abs_min = 0
abs_max = 0
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

def roundToNearest(n, nearest):
	return 1.0 * round(1.0*n/nearest) * nearest

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter='\t')
	next(r, None) # remove header
	for name,type,weight,file,from_gain,to_gain,from_tempo,to_tempo,gain_phase,tempo_phase,tempo_offset,interval_phase,interval,interval_offset,active in r:
		if file and int(active):
			index = len(instruments)
			# build instrument object
			instrument = {
				'index': index,
				'name': name,
				'type': type.lower().replace(' ', '_'),
				'weight': float(weight),
				'file': INSTRUMENTS_DIR + file,
				'from_gain': round(float(from_gain), 2),
				'to_gain': round(float(to_gain), 2),
				'from_tempo': float(from_tempo),
				'to_tempo': float(to_tempo),
				'gain_phase': int(gain_phase),
				'tempo_phase': int(tempo_phase),
				'from_beat_ms': int(round(BEAT_MS/float(from_tempo))),
				'to_beat_ms': int(round(BEAT_MS/float(to_tempo))),
				'tempo_offset': float(tempo_offset),
				'interval_ms': int(int(interval_phase)*BEAT_MS),
				'interval': int(interval),
				'interval_offset': int(interval_offset)
			}
			# add instrument to instruments
			instruments.append(instrument)

# Convert a row of values to values between 0 and 1
def normalizeRow(row, min_value, max_value):
	global PRECISION
	normalized_row = []
	delta = max_value - min_value
	for i, col in enumerate(row):
		if i > 0:
			normalized_row.append(round(1.0 * (col - min_value) / delta, PRECISION))
		else:
			normalized_row.append(col)
	return normalized_row

# Read stations from file
with open(EEG_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	last_ms = 0
	for t,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16,s17,s18,s19,s20,s21,s22,s23 in r:
		ms = int(t)
		row = [ms,float(s1),float(s2),float(s3),float(s4),float(s5),float(s6),float(s7),float(s8),float(s9),float(s10),float(s11),float(s12),float(s13),float(s14),float(s15),float(s16),float(s17),float(s18),float(s19),float(s20),float(s21),float(s22),float(s23)]
		# get row with minimum values
		if ms <= -2:
			eeg_min = row
			abs_min = min(eeg_min)
		# get row with maximum values
		elif ms <= -1:
			eeg_max = row
			abs_max = max(eeg_max)
		# all other rows
		else:
			normalized_row = normalizeRow(row, abs_min, abs_max)
			eeg.append(normalized_row)
			total_ms += (ms - last_ms)
			last_ms = ms

# Calculate total time
total_seconds = int(1.0*total_ms/1000)
print('Total sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + '(' + str(total_seconds) + 's)')

# Sort sequence
sequence = sorted(sequence, key=lambda k: k['elapsed_ms'])

# Add milliseconds to sequence
elapsed = 0
for index, step in enumerate(sequence):
	sequence[index]['milliseconds'] = step['elapsed_ms'] - elapsed
	elapsed = step['elapsed_ms']

# Write instruments to file
if WRITE_SEQUENCE:
	with open(INSTRUMENTS_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)	
		for index, instrument in enumerate(instruments):
			w.writerow([index])
			w.writerow([instrument['file']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote instruments to file: '+INSTRUMENTS_OUTPUT_FILE)

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
		print('Successfully wrote sequence to file: '+SEQUENCE_OUTPUT_FILE)

# Write summary file
if WRITE_REPORT:
	with open(REPORT_SUMMARY_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(['Time', 'Name', 'Duration', 'Beats', 'Instruments'])
		elapsed = 0		
		print('Successfully wrote summary file: '+REPORT_SUMMARY_OUTPUT_FILE)

# Write sequence report to file
if WRITE_REPORT:
	with open(REPORT_SEQUENCE_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(['Time', 'Instrument', 'Gain'])
		for step in sequence:
			instrument = instruments[step['instrument_index']]
			elapsed = step['elapsed_ms']
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = elapsed % 1000
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, instrument['file'], step['gain']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote sequence report to file: '+REPORT_SEQUENCE_OUTPUT_FILE)

# Write JSON data for the visualization
if WRITE_JSON:
	json_data = eeg
	json_data.insert(0, LABELS)
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(json_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
