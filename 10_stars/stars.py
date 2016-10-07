# -*- coding: utf-8 -*-

# Description: builds the sequence file for use with ChucK from the data supplied
# Example usage:
#   python stars.py

import argparse
import csv
import json
import math
import os
import sys

# Input
parser = argparse.ArgumentParser()
parser.add_argument('-in', dest="INPUT_FILE", default="data/sequence.json", help="Path to input json file")
parser.add_argument('-ins', dest="INSTRUMENT_FILE", default="data/ck_instruments.csv", help="Path to output instrument csv file")
parser.add_argument('-seq', dest="SEQUENCE_FILE", default="data/ck_sequence.csv", help="Path to output sequence csv file")
parser.add_argument('-dur', dest="DURATION", default="360000", type=int, help="Duration of song")
parser.add_argument('-g0', dest="MIN_GAIN", default="0.5", type=float, help="Min gain")
parser.add_argument('-g1', dest="MAX_GAIN", default="1.2", type=float, help="Min gain")
parser.add_argument('-hnd', dest="HARMONY_NOTE_DURATION", default="16000", type=int, help="Duration of song")

# Init input
args = parser.parse_args()
DURATION = args.DURATION

def lerp(a, b, percent):
    return (1.0*b - a) * percent + a;

# Init instruments
instruments = [
    { "file": "instruments/D3.wav", "type": "note" },
    { "file": "instruments/Eb3.wav", "type": "note" },
    { "file": "instruments/F3.wav", "type": "note" },
    { "file": "instruments/G3.wav", "type": "note" },
    { "file": "instruments/A3.wav", "type": "note" },
    { "file": "instruments/Bb3.wav", "type": "note" },
    { "file": "instruments/C4.wav", "type": "note" },
    { "file": "instruments/D4.wav", "type": "note" },
    { "file": "instruments/Eb4.wav", "type": "note" },
    { "file": "instruments/F4.wav", "type": "note" },
    { "file": "instruments/G4.wav", "type": "note" },
    { "file": "instruments/ae1_19_a4-x2.wav", "type": "harmony" },
    { "file": "instruments/ae1_06_bb5-x2.wav", "type": "harmony" },
    { "file": "instruments/ae1_27_c5-x8.wav", "type": "harmony" },
    { "file": "instruments/ae1_20_d5-x8.wav", "type": "harmony" },
    { "file": "instruments/ae1_22_eb5-x7.wav", "type": "harmony" },
    { "file": "instruments/ae1_11_f5-x6.wav", "type": "harmony" },
    { "file": "instruments/ae1_02_g5-x2.wav", "type": "harmony" }
]
for i,instrument in enumerate(instruments):
    instruments[i]["index"] = i
notes = [i for i in instruments if i["type"]=="note"]
harmonyNotes = [i for i in instruments if i["type"]=="harmony"]

# Read json file
rows = []
with open(args.INPUT_FILE) as f:
    rows = json.load(f)

# Build notes sequence
sequence = []
for row in rows:
    t = row[0]
    y = row[2]
    mag = row[3]
    sequence.append({
        "instrument_index": notes[int(y * len(notes))]["index"],
        "position": 0,
        "rate": 1,
        "gain": round(lerp(args.MIN_GAIN, args.MAX_GAIN, mag), 3),
        "elapsed_ms": int(round(t * DURATION))
    })

# Add harmony to sequence
dur = args.HARMONY_NOTE_DURATION
ms = 0
while ms < args.DURATION:
    percent = 1.0 * ms / DURATION
    multiplier = math.sin(percent * math.pi)
    sequence.append({
        "instrument_index": harmonyNotes[int(multiplier * len(harmonyNotes))]["index"],
        "position": 0,
        "rate": 1,
        "gain": 3.6,
        "elapsed_ms": ms
    })
    ms += dur

# Sort sequence
sequence = sorted(sequence, key=lambda k: k['elapsed_ms'])

# Add milliseconds to sequence
elapsed = 0
for i, step in enumerate(sequence):
    sequence[i]['milliseconds'] = step['elapsed_ms'] - elapsed
    elapsed = step['elapsed_ms']

# Write instruments
with open(args.INSTRUMENT_FILE, 'wb') as f:
    w = csv.writer(f)
    for index, instrument in enumerate(instruments):
        w.writerow([index])
        w.writerow([instrument['file']])
    f.seek(-2, os.SEEK_END) # remove newline
    f.truncate()
    print "Successfully wrote instrument to file:  %s" % args.INSTRUMENT_FILE

# Write sequence
with open(args.SEQUENCE_FILE, 'wb') as f:
    w = csv.writer(f)
    for step in sequence:
        w.writerow([step['instrument_index']])
        w.writerow([step['position']])
        w.writerow([step['gain']])
        w.writerow([step['rate']])
        w.writerow([step['milliseconds']])
    f.seek(-2, os.SEEK_END) # remove newline
    f.truncate()
    print "Successfully wrote sequence to file:  %s" % args.SEQUENCE_FILE
