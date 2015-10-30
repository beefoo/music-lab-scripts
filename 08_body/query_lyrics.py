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

def addSongMatch(song):
    global song_matches

    matches = [s for s in song_matches if s['url']==song['url']]
    # if already exists, just increment score
    if len(matches) > 0:
        match = matches[0]
        song_matches[match['index']]['score'] += 1
    # add if not already exist
    else:
        song['score'] = 1
        song['index'] = len(song_matches)
        song_matches.append(song)

print "Analyzing..."

# Analyze each song
for song in songs:
    lWords = song['lyrics'].split(' ')
    for lw in lWords:
        matches = [w for w in words if w['word']==lw and w['region']==body_part]
        if len(matches) > 0:
            addSongMatch(song)

# Sort song matches by score
song_matches = sorted(song_matches, key=lambda k: k['score'], reverse=True)

# Report on matches
if len(song_matches) > 0:
    print str(len(song_matches)) + ' matches found: '
else:
    print 'No results found'

for s in song_matches:
    print str(s['score']) + '. ' + s['song'] + ' - ' + s['album'] + ' [' + s['url'] + ']'
