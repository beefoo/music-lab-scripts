# -*- coding: utf-8 -*-

# Usage: python csv_to_json.py data/top_10_movies_2011-2015.csv data/top_10_movies_2011-2015_people.csv data/top_10_movies_2011-2015.json

import csv
import json
import sys

if len(sys.argv) < 3:
    print "Usage: %s <inputfile movie csv> <inputfile people csv> <output json file>" % sys.argv[0]
    sys.exit(1)

MOVIE_FILE = sys.argv[1]
PEOPLE_FILE = sys.argv[2]
OUTPUT_FILE = sys.argv[3]

valid_roles = ['cast']

movies = []
people = []

def getRaces(races):
    the_races = []
    race_key = {
        "w": "White",
        "b": "Black",
        "h": "Hispanic",
        "a": "Asian/Pacific Islander",
        "o": "American Indian",
        "u": "Other/Unknown"
    }
    races = races.split(",")
    unique_races = set(races)
    for r in unique_races:
        the_races.append({
            "id": r,
            "race": race_key[r],
            "percent": 1.0 * len([_r for _r in races if _r==r]) / len(races)
        })
    return the_races

# Read in movies
with open(MOVIE_FILE, 'rb') as f:
    rows = csv.DictReader(f)
    for row in rows:
        movies.append({
            'id': row['movie_id'],
            'year': int(row['year']),
            'rank': int(row['rank']),
            'name': row['name'],
            'gross': int(row['total_gross']),
            'gross_f': "{:,}".format(int(row['total_gross']))
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
    movies[i]['people'] = movie_people

# Write to file
with open(OUTPUT_FILE, 'w') as outfile:
    json.dump(movies, outfile)
    print('Successfully wrote data to file: '+OUTPUT_FILE)
