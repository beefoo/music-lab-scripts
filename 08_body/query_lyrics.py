# -*- coding: utf-8 -*-

import csv
import json
import sys

# retrieve input
if len(sys.argv) < 2:
    print ("Usage: "+sys.argv[0]+" <body part> <artist>")
    sys.exit(1)
body_part = sys.argv[1]
artist = sys.argv[2]

# files
LYRICS_FILE = "data/lyrics.json"
WORDS_FILE = "data/words.csv"

songs = []
words = []
song_matches = []

# Read words
with open(WORDS_FILE, 'rb') as f:
    r = csv.DictReader(f)
    for row in r:
        words.append(row)

# Read songs/lyrics
with open(LYRICS_FILE) as f:
    songs = json.load(f)
# Filter songs for this artist
songs = [s for s in songs if artist.lower() in s['artist'].lower()]
if len(songs) <= 0:
    print "No matches for artist: " + artist
    sys.exit(1)

# Analyze each song
for song in songs:
    lWords = song['lyrics'].split(' ')
