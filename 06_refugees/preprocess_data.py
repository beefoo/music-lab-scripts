# Library dependancies
import csv
import json
import math
import os

COUNTRIES_INPUT_FILE = 'data/countries.csv'
REFUGEES_INPUT_FILE = 'data/refugees.csv'
OUTPUT_FILE = 'data/refugees_processed.csv'

country_codes = []
countries = []
refugees = []

def angleBetweenPoints(x1, y1, x2, y2):
	delta_x = x2 - x1
	delta_y = y2 - y1
	return math.atan2(delta_y, delta_x) * 180.0 / math.pi

def distance(x1, y1, x2, y2):
	return math.sqrt((x1 - x2)**2 + (y1 - y2)**2)

# Read countries from file
with open(COUNTRIES_INPUT_FILE, 'rb') as f:
	r = csv.reader(f, delimiter=',')
	next(r, None) # remove header
	for code,x,y in r:
		countries.append({
			'code': code,
			'x': float(x),
			'y': float(y)
		})
country_codes = [c['code'] for c in countries]

# Read refugees from file
with open(REFUGEES_INPUT_FILE, 'rb') as f:
	lines = csv.reader(f, delimiter=',')
	next(lines, None) # remove header
	for origin,asylum,count,year in lines:
		year = int(year)
		count = int(count)
		
		# Check if valid country code
		if origin in country_codes and asylum in country_codes and origin!=asylum and count>0:
			
			# Retrieve country info
			country_origin = (country for country in countries if country["code"] == origin).next()
			country_asylum = (country for country in countries if country["code"] == asylum).next()
			
			# Check for existing origin-asylum group
			group_match = [i for i,r in enumerate(refugees) if r['origin'] == origin and r['asylum'] == asylum and r['year'] == year]
			if len(group_match) > 0:
				refugees[group_match.next()]['count'] += count
			
			# Otherwise add it
			else:
				refugees.append({
					'origin': origin,
					'asylum': asylum,
					'count': int(count),
					'year': year,
					'origin_x': country_origin['x'],
					'origin_y': country_origin['y'],
					'asylum_x': country_asylum['x'],
					'asylum_y': country_asylum['y'],
					'distance': distance(country_origin['x'], country_origin['y'], country_asylum['x'], country_asylum['y']),
					'angle': angleBetweenPoints(country_origin['x'], country_origin['y'], country_asylum['x'], country_asylum['y'])
		})

# Sort by year
refugees = sorted(refugees, key=lambda k: k['year'])

# Write refugees to file
if len(refugees) > 0:
	with open(OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		columns = refugees[0].keys()
		w.writerow(columns)
		for r in refugees:
			r_columns = []
			for c in columns:
				r_columns.append(r[c])
			w.writerow(r_columns)
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote '+str(len(refugees))+' refugee groups to file: '+OUTPUT_FILE)