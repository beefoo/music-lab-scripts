# -*- coding: utf-8 -*-

import csv
import json

LYRICS_FILE = "data/lyrics.json"
WORDS_FILE = "data/words.csv"
OUTPUT_FILE = "data/analysis.json"
SONG_OUTPUT_FILE = "data/song_analysis.csv"

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
regionMatchCount = 3
songMatchCount = 20

songs = []
words = []
data = []
song_data = []

# Read words
with open(WORDS_FILE, 'rb') as f:
    r = csv.DictReader(f)
    for row in r:
        words.append(row)

# Read songs/lyrics
with open(LYRICS_FILE) as f:
    songs = json.load(f)

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

# Add data
def addData(song, region, value):
    global data

    artist = song['artist']
    matches = [d for d in data if artist==d['artist']]
    match = matches[0]
    i = match['index']
    # Look for gendered matches
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
    # Look for gender-agnostic matches
    regionFound = False
    region = region.split('_')[-1]
    for j,r in enumerate(match['regions_agnostic']):
        if r['name']==region:
            regionFound = True
            data[i]['regions_agnostic'][j]['value'] += value
            break
    if not regionFound:
        data[i]['regions_agnostic'].append({
            'name': region,
            'value': value
        })

def addSongData(song, region):
    global song_data

    matches = [d for d in song_data if song['artist']==d['artist'] and song['song']==d['song'] and song['album']==d['album']]
    match = matches[0]
    i = match['index']
    regionFound = False
    for j,r in enumerate(match['regions']):
        if r['name']==region:
            regionFound = True
            song_data[i]['regions'][j]['value'] += 1
            break
    if not regionFound:
        song_data[i]['regions'].append({
            'name': region,
            'value': 1
        })

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
            'regions_agnostic': [],
            'word_count': 0,
            'value_count': 0
        })
    song_data.append({
        'index': len(song_data),
        'artist': s['artist'],
        'song': s['song'],
        'album': s['album'],
        'url': s['url'],
        'regions': [],
        'score': 0
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
                    addData(song, gender+'_'+match['region'], 2)
                    addSongData(song, match['region'])
                # If not strict, add both genders
                elif not gender and not match['strict']:
                    addData(song, 'male_'+match['region'], 1)
                    addData(song, 'female_'+match['region'], 1)
                    addSongData(song, match['region'])

            # gender-specific body part, add value of two
            else:
                addData(song, match['gender']+'_'+match['region'], 2)
                addSongData(song, match['region'])

    addWordCount(song['artist'], len(lWords))

print "Finished analysis. Calculating percentages..."

# Determine percents
minValue = None
maxValue = None
minValueAgnostic = None
maxValueAgnostic = None
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
    for j, r in enumerate(d['regions_agnostic']):
        # Normalize values to percent of value count
        value_n = 1.0 * r['value'] / d['value_count']
        data[i]['regions_agnostic'][j]['value_n'] = value_n
        # Track min/max
        if minValueAgnostic is None or value_n < minValueAgnostic:
            minValueAgnostic = value_n
        if maxValueAgnostic is None or value_n > maxValueAgnostic:
            maxValueAgnostic = value_n

print "Finished percentages. Normalizing and sorting..."

# Normalize to 0-1
for i, d in enumerate(data):
    for j, r in enumerate(d['regions']):
        data[i]['regions'][j]['value_n'] = (r['value_n']-minValue) / (maxValue-minValue)
    for j, r in enumerate(d['regions_agnostic']):
        data[i]['regions_agnostic'][j]['value_n'] = (r['value_n']-minValueAgnostic) / (maxValueAgnostic-minValueAgnostic)
    # Sort regions
    data[i]['regions'] = sorted(data[i]['regions'], key=lambda k: k['value_n'], reverse=True)
    data[i]['regions_agnostic'] = sorted(data[i]['regions_agnostic'], key=lambda k: k['value_n'], reverse=True)

print "Finished normalizing and sorting. Calculating top song matches..."

for i, d in enumerate(data):
    # Get the artist's top mentioned regions
    top_regions = []
    for j, r in enumerate(d['regions_agnostic']):
        if j < regionMatchCount:
            top_regions.append(r['name'])
    # Retrieve artist's songs
    artist_songs = [s for s in song_data if s['artist']==d['artist']]
    # Give each song a score based on top mentioned regions
    for j, s in enumerate(artist_songs):
        for r in s['regions']:
            if r['name'] in top_regions:
                artist_songs[j]['score'] += r['value']
    # Sort songs by score
    artist_songs = sorted(artist_songs, key=lambda k: k['score'], reverse=True)
    # Add songs to data
    data[i]['top_songs'] = artist_songs[:songMatchCount]

# Save data
with open(OUTPUT_FILE, 'w') as f:
    json.dump(data, f)
    print('Successfully wrote ' + str(len(data)) + ' artists to JSON file: '+OUTPUT_FILE)

# Save song data
with open(SONG_OUTPUT_FILE, 'wb') as f:
    w = csv.writer(f)
    headers = ['artist', 'song', 'album', 'url', 'score']
    w.writerow(headers)
    for d in data:
        for s in d['top_songs']:
            row = []
            for h in headers:
                if isinstance(s[h], basestring):
                    row.append(s[h].encode('utf-8'))
                else:
                    row.append(s[h])
            w.writerow(row)
    print('Successfully wrote to song data file: '+SONG_OUTPUT_FILE)
