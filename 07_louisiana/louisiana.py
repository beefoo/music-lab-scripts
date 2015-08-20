# -*- coding: utf-8 -*-
##
# TRACK 7
# TOO BLUE
# Brian Foo (brianfoo.com)
# This file builds the sequence file for use with ChucK from the data supplied
##

# Library dependancies
import csv
import json
import math
import os
import pprint
import time

# Config
BPM = 100 # Beats per minute, e.g. 60, 75, 100, 120, 150
DIVISIONS_PER_BEAT = 4 # e.g. 4 = quarter notes, 8 = eighth notes, etc
VARIANCE_MS = 20 # +/- milliseconds an instrument note should be off by to give it a little more "natural" feel
GAIN = 0.4 # base gain
TEMPO = 1.0 # base tempo
MS_PER_YEAR = 12000

# Files
INSTRUMENTS_INPUT_FILE = 'data/instruments.csv'
LAND_LOSS_INPUT_FILE = 'data/land_loss.json'
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
BEATS_PER_YEAR = round(MS_PER_YEAR / BEAT_MS)
GROUPS_PER_YEAR = int(BEATS_PER_YEAR)
GROUP_MS = MS_PER_YEAR / GROUPS_PER_YEAR

# Init
years = []
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

# Read instruments from file
with open(INSTRUMENTS_INPUT_FILE, 'rb') as f:
    r = csv.reader(f, delimiter=',')
    next(r, None) # remove header
    for file,min_loss,max_loss,min_c_loss,max_c_loss,from_gain,to_gain,from_tempo,to_tempo,tempo_offset,interval_phase,interval,interval_offset,active in r:
        if int(active):
            index = len(instruments)
            # build instrument object
            _beat_ms = int(round(BEAT_MS/TEMPO))
            instrument = {
                'index': index,
                'file': INSTRUMENTS_DIR + file,
                'min_loss': float(min_loss),
                'max_loss': float(max_loss),
                'min_c_loss': float(min_c_loss),
                'max_c_loss': float(max_c_loss),
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

# Read countries from file
with open(LAND_LOSS_INPUT_FILE) as data_file:
    years = json.load(data_file)

# Break years up into groups
for i, year in enumerate(years):
    # Initialize groups
    groups = []
    for g in range(GROUPS_PER_YEAR):
        groups.append(0)
    # Add losses to groups
    total_loss = len(year['losses'])
    for l in range(total_loss):
        group_i = int(1.0*l / total_loss * GROUPS_PER_YEAR)
        groups[group_i] += 1
    # Update
    years[i]['total_loss'] = total_loss
    years[i]['loss_per_group'] = 1.0 * total_loss / GROUPS_PER_YEAR
    years[i]['groups'] = groups
    years[i]['min_group_value'] = min(groups)
    years[i]['max_group_value'] = max(groups)

# Normalize groups
min_group_value = min([y['min_group_value'] for y in years])
max_group_value = max([y['max_group_value'] for y in years])
for i, year in enumerate(years):
    for g, group in enumerate(year['groups']):
        years[i]['groups'][g] = (1.0 * group - min_group_value) / (max_group_value - min_group_value)
all_years_loss = sum([y['total_loss'] for y in years])

# Calculate total time
total_ms = len(years) * MS_PER_YEAR
total_seconds = int(1.0*total_ms/1000)
print('Main sequence time: '+time.strftime('%M:%S', time.gmtime(total_seconds)) + ' (' + str(total_seconds) + 's)')
print('Ms per beat: ' + str(BEAT_MS))
print('Beats per year: ' + str(BEATS_PER_YEAR))

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
def addBeatsToSequence(instrument, duration, ms, round_to):
    global sequence
    global hindex
    beat_ms = int(roundToNearest(instrument['beat_ms'], round_to))
    offset_ms = int(instrument['tempo_offset'] * instrument['from_beat_ms'])
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
                'gain': getGain(instrument, percent_complete),
                'elapsed_ms': max([elapsed_ms + variance, 0]),
                'duration': min([this_beat_ms, MS_PER_YEAR])
            })
            hindex += 1
        remaining_duration -= this_beat_ms
        elapsed_duration += this_beat_ms
        ms += this_beat_ms

# Build sequence
for instrument in instruments:
    ms = None
    queue_duration = 0
    c_loss = 0
    current_ms = 0

    # Go through each year
    for year in years:
        # c_loss += year['loss']

        for g in year['groups']:
            c_loss += (year['loss_per_group'] / all_years_loss)
            is_valid = g >= instrument['min_loss'] and g < instrument['max_loss'] and c_loss >= instrument['min_c_loss'] and c_loss < instrument['max_c_loss']

            # If not valid, add it queue to sequence
            if not is_valid and queue_duration > 0 and ms != None or is_valid and ms != None and current_ms > (ms+queue_duration):
                addBeatsToSequence(instrument.copy(), queue_duration, ms, ROUND_TO_NEAREST)
                ms = None
                queue_duration = 0

            # If valid, add time to queue
            if is_valid:
                if ms==None:
                    ms = current_ms
                queue_duration += GROUP_MS

            current_ms += GROUP_MS

        # Add remaining queue to sequence
        if queue_duration > 0 and ms != None:
            addBeatsToSequence(instrument.copy(), queue_duration, ms, ROUND_TO_NEAREST)

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
if WRITE_REPORT:
    with open(SUMMARY_OUTPUT_FILE, 'wb') as f:
        w = csv.writer(f)
        header = ['Time', 'Year Start', 'Year End', 'Group', 'Loss', 'Loss Cum']
        w.writerow(header)
        year_start_ms = 0
        cumulative_loss = 0
        for y in years:
            # cumulative_loss += y['loss']
            for gi, g in enumerate(y['groups']):
                cumulative_loss += (y['loss_per_group'] / all_years_loss)
                elapsed = year_start_ms
                elapsed_f = time.strftime('%M:%S', time.gmtime(int(elapsed/1000)))
                ms = int(elapsed % 1000)
                elapsed_f += '.' + str(ms)
                row = [elapsed_f, y['year_start'], y['year_end'], gi, g, cumulative_loss]
                w.writerow(row)
                year_start_ms += GROUP_MS
        print('Successfully wrote summary file: '+SUMMARY_OUTPUT_FILE)

    if len(sequence) > 0:
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
