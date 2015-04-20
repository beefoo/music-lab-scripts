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
BPM = 60 # Beats per minute, e.g. 60, 75, 100, 120, 150
DIVISIONS_PER_BEAT = 16 # e.g. 4 = quarter notes, 8 = eighth notes, etc
BEATS_PER_PAIR = 1
VARIANCE_MS = 20 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 0.5 # base gain
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
WRITE_SEQUENCE = True
WRITE_REPORT = True
WRITE_JSON = True

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
ROUND_TO_NEAREST = round(BEAT_MS/DIVISIONS_PER_BEAT)
PAIR_MS = BEATS_PER_PAIR * BEAT_MS

print('Building sequence at '+str(BPM)+' BPM ('+str(BEAT_MS)+'ms per beat)')

# Initialize Variables
instruments = []
pairs = []
sequence = []
hindex = 0
total_ms = 0
min_percent = None
max_percent = None
min_total = None
max_total = None
min_year = None
max_year = None
min_diff = None
max_diff = None

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
def mean(data, key):
    n = len(data)
    if n < 1:
		return 0
    else:
		list = [i[key] for i in data]
		return sum(list)/n
	
# round {n} to nearest {nearest}
def roundToNearest(n, nearest):
	return 1.0 * round(1.0*n/nearest) * nearest

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	for file,f_percent_min,f_percent_max,m_percent_min,m_percent_max,t_percent_min,t_percent_max,f_avg_min,f_avg_max,m_avg_min,m_avg_max,t_avg_min,t_avg_max,rvb_max,gain,tempo,tempo_offset,interval_phase,interval,interval_offset,active in r:
		if int(active):
			index = len(instruments)
			# build instrument object
			_beat_ms = int(round(BEAT_MS/(float(tempo)*TEMPO)))
			instrument = {
				'file': INSTRUMENTS_DIR + file,
				'index': index,
				'f_percent_min': float(f_percent_min),
				'f_percent_max': float(f_percent_max),
				'm_percent_min': float(m_percent_min),
				'm_percent_max': float(m_percent_max),
				't_percent_min': float(t_percent_min),
				't_percent_max': float(t_percent_max),
				'f_avg_min': float(f_avg_min),
				'f_avg_max': float(f_avg_max),
				'm_avg_min': float(m_avg_min),
				'm_avg_max': float(m_avg_max),
				't_avg_min': float(t_avg_min),
				't_avg_max': float(t_avg_max),
				'rvb_max': float(rvb_max),
				'gain': float(gain) * GAIN,
				'to_tempo': float(tempo) * TEMPO,
				'tempo_offset': float(tempo_offset),
				'interval_ms': int(int(interval_phase)*_beat_ms),
				'interval': int(interval),
				'interval_offset': int(interval_offset),
				'beat_ms': _beat_ms
			}
			# add instrument to instruments
			instruments.append(instrument)

# Read pairs from file
elapsed = 0
with open(PAIRS_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	for _order, _f_race, _m_race, _f_percent, _m_percent, _diff, _total, _year in r:
		# Keep track of min/max
		if min_percent is None:
			min_percent = int(_f_percent)
		if max_percent is None:
			max_percent = int(_f_percent)
		if min_total is None:
			min_total = int(_total)
		if max_total is None:
			max_total = int(_total)
		if min_year is None:
			min_year = int(_year)
		if max_year is None:
			max_year = int(_year)
		if min_diff is None:
			min_diff = int(_diff)
		if max_diff is None:
			max_diff = int(_diff)
		min_percent = min([min_percent, int(_f_percent), int(_m_percent)])
		max_percent = max([max_percent, int(_f_percent), int(_m_percent)])
		min_total = min([min_total, int(_total)])
		max_total = max([max_total, int(_total)])
		min_year = min([min_year, int(_year)])
		max_year = max([max_year, int(_year)])
		min_diff = min([min_diff, int(_diff)])
		max_diff = max([max_diff, int(_diff)])
		# Add pair to list
		index = len(pairs)
		pairs.append({
			'index': index,
			'f_race': _f_race,
			'm_race': _m_race,
			'f_percent': int(_f_percent),
			'm_percent': int(_m_percent),
			'diff_percent': int(_diff),
			'total': int(_total),
			'year': int(_year),
			'start_ms': elapsed,
			'stop_ms': elapsed + PAIR_MS
		})
		elapsed += PAIR_MS

# Report pair data
print('Retrieved pairs data with '+ str(len(pairs)) + ' data points')
print('Percent range: ['+str(min_percent)+','+str(max_percent)+']')
print('Total range: ['+str(min_total)+','+str(max_total)+']')

# Calculate total time
total_beats = 1.0 * len(pairs) * BEATS_PER_PAIR
total_ms = elapsed
total_seconds = int(1.0*total_ms/1000)
print('Main sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + ' (' + str(total_seconds) + 's, '+str(total_beats)+' beats)')
print(str(PAIR_MS)+'ms per pair')
print(str(PAIR_MS*6)+'ms per pair total')

# Add normalized values
for i, pair in enumerate(pairs):	
	f_percent = (1.0 * pair['f_percent'] - min_percent) / (max_percent - min_percent)
	m_percent = (1.0 * pair['m_percent'] - min_percent) / (max_percent - min_percent)
	total = (1.0 * pair['total'] - min_total) / (max_total - min_total)
	diff_percent = (1.0 * pair['diff_percent'] - min_diff) / (max_diff - min_diff)
	pairs[i]['f_percent_n'] = f_percent
	pairs[i]['m_percent_n'] = m_percent
	pairs[i]['total_n'] = total
	pairs[i]['diff_percent_n'] = diff_percent

# Add pair averages
avg_queue = []
for i, pair in enumerate(pairs):
	avg_queue.append(pair.copy())
	if pair['year'] >= max_year:
		f_avg = mean(avg_queue, 'f_percent_n')
		m_avg = mean(avg_queue, 'm_percent_n')
		t_avg = mean(avg_queue, 'total_n')
		for p in avg_queue:
			pairs[p['index']]['f_percent_n_avg'] = f_avg
			pairs[p['index']]['m_percent_n_avg'] = m_avg
			pairs[p['index']]['total_n_avg'] = t_avg
		avg_queue = []

# Return if the instrument should be played in the given interval
def isValidInterval(instrument, elapsed_ms):
	interval_ms = instrument['interval_ms']
	interval = instrument['interval']
	interval_offset = instrument['interval_offset']	
	return int(math.floor(1.0*elapsed_ms/interval_ms)) % interval == interval_offset

# Add beats to sequence
def addBeatsToSequence(instrument, rvb, duration, ms, beat_ms, round_to):
	global sequence
	global hindex
	offset_ms = int(instrument['tempo_offset'] * instrument['beat_ms'])
	ms += offset_ms
	previous_ms = int(ms)
	remaining_duration = int(duration)
	elapsed_duration = offset_ms
	while remaining_duration > 0:
		elapsed_ms = int(ms)
		percent_complete = 1.0 * elapsed_duration / duration
		this_beat_ms = instrument['beat_ms']
		# add to sequence if in valid interval
		if isValidInterval(instrument, elapsed_ms):
			h = halton(hindex, 3)
			variance = int(h * VARIANCE_MS * 2 - VARIANCE_MS)
			sequence.append({
				'instrument_index': instrument['index'],
				'instrument': instrument,
				'position': 0,
				'rate': 1,
				'gain': instrument['gain'],
				'reverb': round(rvb,2),
				'elapsed_ms': max([elapsed_ms + variance, 0])
			})
			hindex += 1
		remaining_duration -= this_beat_ms
		elapsed_duration += this_beat_ms
		ms += this_beat_ms

# Build sequence
for instrument in instruments:
	ms = 0
	queue_duration = 0
	fp0 = instrument['f_percent_min']
	fp1 = instrument['f_percent_max']
	mp0 = instrument['m_percent_min']
	mp1 = instrument['m_percent_max']
	tp0 = instrument['t_percent_min']
	tp1 = instrument['t_percent_max']
	fa0 = instrument['f_avg_min']
	fa1 = instrument['f_avg_max']
	ma0 = instrument['m_avg_min']
	ma1 = instrument['m_avg_max']
	ta0 = instrument['t_avg_min']
	ta1 = instrument['t_avg_max']	
	# Each pair
	for pair in pairs:
		# Check if instrument is valid for this pair
		fp = pair['f_percent_n']
		mp = pair['m_percent_n']
		tp = pair['total_n']
		fa = pair['f_percent_n_avg']
		ma = pair['m_percent_n_avg']
		ta = pair['total_n_avg']
		is_valid = (fp>=fp0 and fp<fp1 and mp>=mp0 and mp<mp1 and tp>=tp0 and tp<tp1 and fa>=fa0 and fa<fa1 and ma>=ma0 and ma<ma1 and ta>=ta0 and ta<ta1)
		if instrument['rvb_max'] > 0:
			if is_valid:
				rvb = pair['diff_percent_n'] * instrument['rvb_max']
				addBeatsToSequence(instrument.copy(), rvb, PAIR_MS, ms, BEAT_MS, ROUND_TO_NEAREST)
			ms += PAIR_MS
		else:
			# Instrument not here, just add the pair duration and continue
			if not is_valid and queue_duration > 0:
				addBeatsToSequence(instrument.copy(), 0, queue_duration, ms, BEAT_MS, ROUND_TO_NEAREST)
				ms += queue_duration + PAIR_MS
				queue_duration = 0
			elif not is_valid:
				ms += PAIR_MS
			else:
				queue_duration += PAIR_MS
	if queue_duration > 0:
		addBeatsToSequence(instrument.copy(), 0, queue_duration, ms, BEAT_MS, ROUND_TO_NEAREST)

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
			w.writerow([step['reverb']])
			w.writerow([step['milliseconds']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote sequence to file: '+SEQUENCE_OUTPUT_FILE)

# Write summary files
if WRITE_REPORT:
	with open(REPORT_SUMMARY_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(['Time', 'Year', 'F Race', 'M Race', 'F Percent', 'M Percent', 'T Percent', 'F Avg', 'M Avg', 'T Avg'])
		for pair in pairs:
			elapsed = pair['start_ms']
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, pair['year'], pair['f_race'], pair['m_race'], pair['f_percent_n'], pair['m_percent_n'], pair['total_n'], pair['f_percent_n_avg'], pair['m_percent_n_avg'], pair['total_n_avg']])
		print('Successfully wrote summary file: '+REPORT_SUMMARY_OUTPUT_FILE)

# Write sequence report to file
if WRITE_REPORT and len(sequence) > 0:
	with open(REPORT_SEQUENCE_OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(['Time', 'Instrument', 'Gain', 'Reverb'])
		for step in sequence:
			instrument = instruments[step['instrument_index']]
			elapsed = step['elapsed_ms']
			elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
			ms = int(elapsed % 1000)
			elapsed_f += '.' + str(ms)
			w.writerow([elapsed_f, instrument['file'], step['gain'], step['reverb']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote sequence report to file: '+REPORT_SEQUENCE_OUTPUT_FILE)

# Write JSON data for the visualization
if WRITE_JSON:
	json_data = {
		'min_percent': min_percent,
		'max_percent': max_percent,
		'min_year': min_year,
		'max_year': max_year,
		'pairs': pairs
	}
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(json_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
