# -*- coding: utf-8 -*-

# Usage: python csv_to_json.py data/top_10_movies_2006-2015.csv data/top_10_movies_2006-2015_people.csv data/top_10_movies_2006-2015.json data/races.json

import csv
import json
import math
import sys

if len(sys.argv) < 4:
    print "Usage: %s <inputfile movie csv> <inputfile people csv> <output movies json file> <output race json file>" % sys.argv[0]
    sys.exit(1)

MOVIE_FILE = sys.argv[1]
PEOPLE_FILE = sys.argv[2]
OUTPUT_MOVIE_FILE = sys.argv[3]
OUTPUT_RACE_FILE = sys.argv[4]

valid_roles = ['cast']
race_config = [
    {"key": "w", "label": "White", "color": "#00a9ff"},
    {"key": "b", "label": "Black", "color": "#81db7a"},
    {"key": "h", "label": "Hispanic/Latino", "color": "#e0d44e"},
    {"key": "a", "label": "Asian/Pacific Islander", "color": "#dd6868"},
    {"key": "o", "label": "American Indian", "color": "#c46bd6"},
    {"key": "u", "label": "Other/Unknown", "color": "#c9bbbb"}
]

movies = []
people = []

# normalize values
def normalize(val, min_val, max_val):
    return 1.0 * (val - min_val) / (max_val - min_val)

def getRaces(races):
    global race_key
    the_races = {}
    races = races.split(",")
    unique_races = set(races)
    for r in unique_races:
        the_races[r] = 1.0 * len([_r for _r in races if _r==r]) / len(races)
    return the_races

# Read in movies
with open(MOVIE_FILE, 'rb') as f:
    rows = csv.DictReader(f)
    for row in rows:
        movies.append({
            'imdb_id': row['imdb_id'],
            'year': int(row['year']),
            'rank': int(row['rank']),
            'name': row['name'],
            'gross': int(row['total_gross']),
            'gross_f': "${:,}".format(int(row['total_gross']))
        })

# Read in people
with open(PEOPLE_FILE, 'rb') as f:
    rows = csv.DictReader(f)
    for row in rows:
        people.append({
            'movie_imdb_id': row['movie_imdb_id'],
            'order': int(row['order']),
            'name': row['name'],
            'role': row['role'],
            'imdb_id': row['imdb_id'],
            'gender': row['gender'],
            'races': getRaces(row['races']),
            'note': row['note'],
            'reference_url': row['reference_url'],
            'voice': int(row['voice'])
        })

# Add people to movies
for i, m in enumerate(movies):
    movie_people = [p for p in people if p['movie_imdb_id']==m['imdb_id']]
    movie_people = sorted(movie_people, key=lambda k: k['order'])
    movies[i]['people'] = movie_people

    # get genders
    gender_list = [p['gender'] for p in movie_people]
    genders = {
        'm': 1.0 * len([g for g in gender_list if g=='m']) / len(gender_list),
        'f': 1.0 * len([g for g in gender_list if g=='f']) / len(gender_list),
        'o': 1.0 * len([g for g in gender_list if g=='o']) / len(gender_list)
    }
    movies[i]['genders'] = genders

    # get races
    races = dict(zip([r['key'] for r in race_config], [0] * len(race_config)))
    for p in movie_people:
        for key, value in p['races'].iteritems():
            races[key] += value
    for key, value in races.iteritems():
        races[key] = 1.0 * value / len(movie_people)
    movies[i]['races'] = races

    # gender score is higher w/ more females
    movies[i]['gender_score'] = round(genders['f'] - genders['m'], 2)

    # people-of-color score is higher with poc
    movies[i]['poc_score'] = round(sum([v for k, v in races.iteritems() if k!='w']) - races['w'], 2)

    # diversity score is higher w/ more unique races
    movies[i]['diversity_score'] = round(len([v for k, v in races.iteritems() if v > 0]), 2)

# Get min/max scores
min_gender_score = min([m['gender_score'] for m in movies])
max_gender_score = max([m['gender_score'] for m in movies])
min_poc_score = min([m['poc_score'] for m in movies])
max_poc_score = max([m['poc_score'] for m in movies])
min_diversity_score = min([m['diversity_score'] for m in movies])
max_diversity_score = max([m['diversity_score'] for m in movies])

# Normalize scores
for i, m in enumerate(movies):
    movies[i]['gender_score'] = normalize(m['gender_score'], min_gender_score, max_gender_score)
    movies[i]['poc_score'] = normalize(m['poc_score'], min_poc_score, max_poc_score)
    movies[i]['diversity_score'] = normalize(m['diversity_score'], min_diversity_score, max_diversity_score)

# Write to file
with open(OUTPUT_MOVIE_FILE, 'w') as outfile:
    json.dump(movies, outfile)
    print('Successfully wrote movies to file: '+OUTPUT_MOVIE_FILE)
with open(OUTPUT_RACE_FILE, 'w') as outfile:
    json.dump(race_config, outfile)
    print('Successfully wrote races to file: '+OUTPUT_RACE_FILE)
