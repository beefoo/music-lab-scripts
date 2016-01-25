# -*- coding: utf-8 -*-

# Usage: python csv_to_json.py data/top_10_movies_2011-2015.csv data/top_10_movies_2011-2015_people.csv data/top_10_movies_2011-2015.json data/races.json

import csv
import json
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
    {"key": "h", "label": "Hispanic", "color": "#e0d44e"},
    {"key": "a", "label": "Asian/Pacific Islander", "color": "#dd6868"},
    {"key": "o", "label": "American Indian", "color": "#c46bd6"},
    {"key": "u", "label": "Other/Unknown", "color": "#c9bbbb"}
]

movies = []
people = []

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
            'id': row['movie_id'],
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
        if row['role'] in valid_roles:
            people.append({
                'movie_id': row['movie_id'],
                'order': int(row['order']),
                'name': row['name'],
                'imdb_id': row['imdb_id'],
                'gender': row['gender'],
                'races': getRaces(row['races']),
                'note': row['note'],
                'reference_url': row['reference_url'],
                'voice': int(row['voice'])
            })

# Add people to movies
for i, m in enumerate(movies):
    movie_people = [p for p in people if p['movie_id']==m['id']]
    movie_people = sorted(movie_people, key=lambda k: k['order'])
    for j, p in enumerate(movie_people):
        movie_people[j]['movie_imdb_id'] = m['imdb_id']
    movies[i]['people'] = movie_people

# Write to file
with open(OUTPUT_MOVIE_FILE, 'w') as outfile:
    json.dump(movies, outfile)
    print('Successfully wrote movies to file: '+OUTPUT_MOVIE_FILE)
with open(OUTPUT_RACE_FILE, 'w') as outfile:
    json.dump(race_config, outfile)
    print('Successfully wrote races to file: '+OUTPUT_RACE_FILE)
