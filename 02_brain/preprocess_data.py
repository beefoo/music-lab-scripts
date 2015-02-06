##
# This file takes raw data from the CHB-MIT Scalp EEG Database (http://www.physionet.org/pn6/chbmit/)
# and creates a normalized CSV file for the main script (brain.py) to use
##

# Library dependancies
import csv
import math
import os

INPUT_FILE = 'data/chb01_15_data.txt'
OUTPUT_FILE = 'data/eeg.csv'
SEIZURE_START = 1732 # in seconds
SEIZURE_END = 1772 # in seconds
SONG_START = SEIZURE_START - 120 # in seconds
SONG_END = SEIZURE_END + 120 # in seconds
SONG_LENGTH = SONG_END - SONG_START
UNIT = 10 # in milliseconds
PRECISION = 6 # decimal places in seconds

def floorToNearest(n, nearest):
	return 1.0 * math.floor(1.0*n/nearest) * nearest

rows = []
min_row = [-2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
max_row = [-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

def addRow(row):
	global rows
	global min_row
	global max_row
	rows.append(row)
	for index, col in enumerate(row):
		if index > 0:
			if col < min_row[index]:
				min_row[index] = col
			if col > max_row[index]:
				max_row[index] = col

# Read data from file
with open(INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	last_fms = -1
	for t,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16,s17,s18,s19,s20,s21,s22,s23 in r:
		time = float(t)		
		if time >= SONG_START and time <= SONG_END:
			ms = round(time * 1000) - SONG_START * 1000
			fms = int(floorToNearest(ms, UNIT))
			if fms != last_fms:
				addRow([fms, float(s1),float(s2),float(s3),float(s4),float(s5),float(s6),float(s7),float(s8),float(s9),float(s10),float(s11),float(s12),float(s13),float(s14),float(s15),float(s16),float(s17),float(s18),float(s19),float(s20),float(s21),float(s22),float(s23)])
			last_fms = fms
		elif time > SONG_END:
			break

with open(OUTPUT_FILE, 'wb') as f:
	w = csv.writer(f)
	w.writerow(['Time','S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13','S14','S15','S16','S17','S18','S19','S20','S21','S22','S23'])
	w.writerow(min_row)
	w.writerow(max_row)
	for row in rows:
		w.writerow(row)
	f.seek(-2, os.SEEK_END) # remove newline
	f.truncate()
	print('Successfully wrote to file: '+OUTPUT_FILE)
