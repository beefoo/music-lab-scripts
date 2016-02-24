# -*- coding: utf-8 -*-
##
# TRACK 9
# HOLLYWOOD IN C
# Brian Foo (brianfoo.com)
# This file builds the sequence file for use with ChucK from the data supplied
##

# Library dependancies
import collections
import csv
import json
import math
import os
from pprint import pprint
import sys
import time

# Config
BPM = 60 # Beats per minute, e.g. 60, 75, 100, 120, 150
DIVISIONS_PER_BEAT = 8 # e.g. 4 = quarter notes, 8 = eighth notes, etc
VARIANCE_MS = 20 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 0.6 # base gain
TEMPO = 1.0 # base tempo
MS_PER_MOVIE = 3000
MIN_GAIN = 0.6
MAX_GAIN = 1.0

# Files
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
MOVIES_INPUT_FILE = 'data/top_10_movies_2006-2015.json'
SUMMARY_OUTPUT_FILE = 'data/report_summary.csv'
SUMMARY_SEQUENCE_OUTPUT_FILE = 'data/report_sequence.csv'
INSTRUMENTS_OUTPUT_FILE = 'data/ck_instruments.csv'
SEQUENCE_OUTPUT_FILE = 'data/ck_sequence.csv'
INSTRUMENTS_DIR = 'instruments/'

# Output options
WRITE_SEQUENCE = True
WRITE_REPORT = True

# Calculations
BEAT_MS = round(60.0 / BPM * 1000)
ROUND_TO_NEAREST = round(BEAT_MS / DIVISIONS_PER_BEAT)
BEATS_PER_MOVIE = round(MS_PER_MOVIE / BEAT_MS)

# Init
movies = []
instruments = []
sequence = []
hindex = 0

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

# interpolate values
def lerp(amt, min_val, max_val):
    return (max_val - min_val) * amt + min_val

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
    r = csv.reader(f, delimiter=',')
    next(r, None) # remove header
    for file, phrase, gender, race, min_count, max_count, from_gain, to_gain, from_tempo, to_tempo, tempo_offset, interval_phase, interval, interval_offset, active in r:
        if int(active):
            index = len(instruments)
            # build instrument object
            _beat_ms = int(round(BEAT_MS/TEMPO))
            instrument = {
                'index': index,
                'file': INSTRUMENTS_DIR + file,
                'gender': gender,
                'race': race,
                'min_count': int(min_count),
                'max_count': int(max_count),
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

# Read movies from file
with open(MOVIES_INPUT_FILE) as data_file:
    movies = json.load(data_file)

# Calculate total time
total_ms = len(movies) * MS_PER_MOVIE
total_seconds = int(1.0*total_ms/1000)
print('Main sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + ' (' + str(total_seconds) + 's)')
print('Ms per beat: ' + str(BEAT_MS))
print('Beats per movie: ' + str(BEATS_PER_MOVIE))

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
def addBeatsToSequence(instrument, duration, ms, round_to, gain_multiplier):
    global sequence
    global hindex

    beat_ms = int(roundToNearest(instrument['beat_ms'], round_to))
    offset_ms = int(instrument['tempo_offset'] * instrument['from_beat_ms'])
    if offset > 0:
        offset_ms = int(offset * instrument['beat_ms'])
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
                'gain': getGain(instrument, percent_complete) * gain_multiplier,
                'elapsed_ms': max([elapsed_ms + variance, 0]),
                'duration': min([this_beat_ms, MS_PER_MOVIE])
            })
            hindex += 1
        remaining_duration -= this_beat_ms
        elapsed_duration += this_beat_ms
        ms += this_beat_ms

# Build sequence
for i in instruments:
    ms = None
    queue_duration = 0

    # Go through each movie
    for mi, m in enumerate(movies):

        offset = 0
        genders = [p['gender'] for p in m['people']]
        races = [p['races'].keys() for p in m['people']]
        races = [r for r in races for r in r]

        # Calculate individual's w/ instrument's race
        race_counts = collections.Counter(races)
        race_count = 0
        if i['race'] in race_counts:
            race_count = race_counts[i['race']]

        # Calculate percent race
        race_percent = 1.0 * race_count / len(races)
        gain_multiplier = lerp(race_percent, MIN_GAIN, MAX_GAIN)

        is_valid = i['gender'] in genders and i['race'] in races and race_count >= i['min_count'] and race_count <= i['max_count']

        if not is_valid and queue_duration > 0 and ms != None:
            addBeatsToSequence(i.copy(), queue_duration, ms, ROUND_TO_NEAREST, gain_multiplier)
            ms = None
            queue_duration = 0

        if is_valid:
            if ms==None:
                ms = mi * MS_PER_MOVIE
            queue_duration += MS_PER_MOVIE
            # offset += 1

    if queue_duration > 0 and ms != None:
        addBeatsToSequence(i.copy(), queue_duration, ms, ROUND_TO_NEAREST, gain_multiplier)

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
if WRITE_REPORT and len(sequence) > 0:

    with open(SUMMARY_OUTPUT_FILE, 'wb') as f:
        w = csv.writer(f)
        w.writerow(['Movie', 'Time', 'Gender', 'POC', 'Diversity'])
        elapsed = 0
        for m in movies:
            elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
            w.writerow([m['name'], elapsed_f, m['gender_score'], m['poc_score'], m['diversity_score']])
            elapsed += MS_PER_MOVIE
        print('Successfully wrote report to file: '+SUMMARY_OUTPUT_FILE)

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
