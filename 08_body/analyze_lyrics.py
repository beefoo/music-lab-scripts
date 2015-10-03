# -*- coding: utf-8 -*-

import csv
import json

LYRICS_FILE = "data/lyrics.json"
WORDS_FILE = "data/words.csv"
OUTPUT_FILE = "data/analysis.json"

possessiveWords = {
    'his': 'male',
    'her': 'female',
    'my': 'self',
    'ma': 'self',
    'your': 'opposite',
    'you': 'opposite',
    'ya': 'opposite'
}
subjectWords = {
    'he': 'male',
    'she': 'female',
    'i': 'self',
    'you': 'opposite'
}
objectWords = {
    'him': 'male',
    'her': 'female',
    'me': 'self',
    'you': 'opposite'
}
wordBuffer = 4

songs = []
words = []
data = []

# Read words
with open(WORDS_FILE, 'rb') as f:
    r = csv.DictReader(f)
    for row in r:
        words.append(row)

# Read songs/lyrics
with open(LYRICS_FILE) as f:
    songs = json.load(f)

# Add data
def addData(artist, region, value):
    global data

    matches = [d for d in data if artist==d['artist']]
    match = matches[0]
    i = match['index']
    regionFound = False
    for j,r in enumerate(match['regions']):
        if r['name']==region:
            regionFound = True
            data[i]['regions'][j]['value'] += value
            break
    if not regionFound:
        data[i]['regions'].append({
            'name': region,
            'value': value
        })
    data[i]['value_count'] += value

# Add word count
def addWordCount(artist, value):
    global data

    matches = [d for d in data if artist==d['artist']]
    match = matches[0]
    data[match['index']]['word_count'] += value

def swapGender(gender):
    if gender=='male':
        return 'female'
    else:
        return 'male'

# Init data
for s in songs:
    if not [d for d in data if d['artist']==s['artist']]:
        data.append({
            'index': len(data),
            'artist': s['artist'],
            'regions': [],
            'word_count': 0,
            'value_count': 0
        })

print "Analyzing..."

# Analyze each song
for song in songs:
    lWords = song['lyrics'].split(' ')
    for i,lw in enumerate(lWords):
        bufferLeft = lWords[max(i-wordBuffer,0):i]
        bufferRight = lWords[min(i+1,len(lWords)-1):min(i+1+wordBuffer,len(lWords)-1)]
        matches = [w for w in words if w['word']==lw]
        for match in matches:
            # This word could apply to either gender
            if match['gender']=='both':
                gender = ""

                # This is an action word, so look at the subject and object (e.g. I kissed her)
                if match['action']:
                    # Look to the left for gendered subject words
                    for w in bufferLeft:
                        if w in subjectWords:
                            gender = subjectWords[w]
                            break
                    # Look to the right for gendered object words
                    if not gender:
                        for w in bufferRight:
                            if w in objectWords:
                                gender = objectWords[w]
                                break

                # Otherwise, this is a noun (e.g. her butt)
                else:
                    # Look left for gendered possessive words
                    for w in bufferLeft:
                        if w in possessiveWords:
                            gender = possessiveWords[w]
                            break

                # Determine gender for self/opposite
                if gender=='self':
                    gender = song['gender']
                elif gender=='opposite':
                    gender = swapGender(song['gender'])
                # Found gender, add that gender
                if gender:
                    addData(song['artist'], gender+'_'+match['region'], 2)
                # If not strict, add both genders
                elif not gender and not match['strict']:
                    addData(song['artist'], 'male_'+match['region'], 1)
                    addData(song['artist'], 'female_'+match['region'], 1)

            # gender-specific body part, add value of two
            else:
                addData(song['artist'], match['gender']+'_'+match['region'], 2)

    addWordCount(song['artist'], len(lWords))

print "Finished analysis. Calculating percentages..."

# Determine percents
minValue = None
maxValue = None
for i, d in enumerate(data):
    for j, r in enumerate(d['regions']):
        # Normalize values to percent of value count
        value_n = 1.0 * r['value'] / d['value_count']
        data[i]['regions'][j]['value_n'] = value_n
        # Track min/max
        if minValue is None or value_n < minValue:
            minValue = value_n
        if maxValue is None or value_n > maxValue:
            maxValue = value_n

print "Finished percentages. Normalizing..."

# Normalize to 0-1
for i, d in enumerate(data):
    for j, r in enumerate(d['regions']):
        data[i]['regions'][j]['value_n'] = (r['value_n']-minValue) / (maxValue-minValue)

# Save data
with open(OUTPUT_FILE, 'w') as f:
    json.dump(data, f)
    print('Successfully wrote ' + str(len(data)) + ' artists to JSON file: '+OUTPUT_FILE)
