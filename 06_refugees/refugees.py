##
# TRACK 6
# REFUGEES
# Brian Foo (brianfoo.com)
# This file builds the sequence file for use with ChucK from the data supplied
##

# Library dependancies
import csv
import json
import math
import os
import time

COUNTRIES_INPUT_FILE = 'data/countrycodes.json'
POPULATIONS_INPUT_FILE = 'data/populations.json'
REFUGEES_INPUT_FILE = 'data/refugees_processed.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/years_refugees.json'

WRITE_VIS = True

MS_PER_YEAR = 4000
START_YEAR = 1975
STOP_YEAR = 2012

countries = []
populations = []
world_populations = {}
refugees = []
years = []

# Mean of list
def mean(data):
    if iter(data) is data:
		data = list(data)
    n = len(data)
    if n < 1:
		return 0
    else:
		return sum(data)/n

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

# Read countries from file
with open(COUNTRIES_INPUT_FILE) as data_file:    
	countries = json.load(data_file)

# Read populations from file
with open(POPULATIONS_INPUT_FILE) as data_file:    
	populations = json.load(data_file)
	world_populations = (p for p in populations if p['code'] == 'WLD').next()

# Read refugees from file
with open(REFUGEES_INPUT_FILE, 'rb') as f:
	lines = csv.reader(f, delimiter=',')
	next(lines, None) # remove header
	for origin,count,angle,origin_y,origin_x,year,asylum_x,asylum_y,asylum,distance in lines:
		year = int(year)
		if year >= START_YEAR and year <= STOP_YEAR:
			refugees.append({
				'origin': origin,
				'origin_name': (country['name'] for country in countries if country['code'] == origin).next(),
				'asylum': asylum,
				'count': int(count),
				'year': year,
				'origin_x': float(origin_x),
				'origin_y': float(origin_y),
				'asylum_x': float(asylum_x),
				'asylum_y': float(asylum_y),
				'distance': float(distance),
				'angle': float(angle)
			})

# Calc min/max
min_refugees = min([r['count'] for r in refugees])
max_refugees = max([r['count'] for r in refugees])
min_distance = min([r['distance'] for r in refugees])
max_distance = max([r['distance'] for r in refugees])
min_year = min([r['year'] for r in refugees])
max_year = max([r['year'] for r in refugees])

# Normalize data
for i,r in enumerate(refugees):
	refugees[i]['count_n'] = (1.0 * r['count'] - min_refugees) / (max_refugees - min_refugees)
	refugees[i]['distance_n'] = (1.0 * r['distance'] - min_distance) / (max_distance - min_distance)

# Report stats
print(str(max_year-min_year) + ' years: [' + str(min_year) + ',' + str(max_year) + ']')
print('Refugees range: [' + str(min_refugees) + ',' + str(max_refugees) + ']')

# Group by years
current_year = None
for r in refugees:
	if r['year'] != current_year:
		year = {
			'year': r['year'],
			'refugees': [r.copy()],
			'population': world_populations[str(r['year'])]
		}
		years.append(year)
		current_year = r['year']
	else:
		years[-1]['refugees'].append(r.copy())

# Process data
ms = 0
for i,y in enumerate(years):
	# Order refugees in each year
	years[i]['refugees'] = sorted(y['refugees'], key=lambda k: k['count'], reverse=True)
	years[i]['count'] = sum([r['count'] for r in y['refugees']])
	
	# Generate origin countries
	origin_codes = set([r['origin'] for r in y['refugees']])
	origin_countries = []
	for code in origin_codes:
		origin_refugees = [r for r in y['refugees'] if r['origin']==code]
		ref = origin_refugees[0]
		origin_countries.append({
			'code': code,
			'name': ref['origin_name'],
			'count': sum([r['count'] for r in origin_refugees]),
			'x': ref['origin_x'],
			'y': ref['origin_y'],
			'avg_distance': mean([r['distance'] for r in origin_refugees])
		})
	
	# Normalize distances
	years[i]['max_distance'] = max([r['distance'] for r in y['refugees']])	
	for j,r in enumerate(y['refugees']):
		years[i]['refugees'][j]['year_distance_n'] = 1.0 * r['distance'] / years[i]['max_distance']
	
	# Sort country counts
	years[i]['countries'] = sorted(origin_countries, key=lambda k: k['count'], reverse=True)
	
	# Determine start/stop times
	years[i]['start_ms'] = ms
	years[i]['stop_ms'] = ms + MS_PER_YEAR
	ms += MS_PER_YEAR
	# print(str(y['year']) + ': ' + str(len(y['refugees'])) + ', ' + str(sum([r['count'] for r in y['refugees']])))

# Normalize country counts
year_countries = [y['countries'] for y in years]
year_countries = [item for sublist in year_countries for item in sublist]
max_country_count = max([c['count'] for c in year_countries])
for i,y in enumerate(years):	
	for j,c in enumerate(y['countries']):
		years[i]['countries'][j]['count_n'] = 1.0 * c['count'] / max_country_count

# Build visualization data
vis_data = []
for y in years:
	year = {
		'y': y['year'],
		'ms0': y['start_ms'],
		'ms1': y['stop_ms'],
		'rc': "{:,}".format(y['count']),
		'p': "{:,}".format(y['population']),
		'cp': "{:,}".format(int(round(y['population']/y['count']))),
		'r': [],
		'c': []
	}
	for c in y['countries']:
		year['c'].append({
			'n': c['name'],
			'x': c['x'],
			'y': c['y'],
			'c': c['count'],
			'cn': c['count_n']
		})
	for i,r in enumerate(y['refugees']):
		rand = halton(i, 3)
		year['r'].append({
			'ms0': y['start_ms'],
			'ms1': y['start_ms'] + r['year_distance_n'] * MS_PER_YEAR,
			'x1': r['origin_x'],
			'y1': r['origin_y'],
			'x2': r['asylum_x'],
			'y2': r['asylum_y'],
			'd': r['distance'],
			'dn': r['distance_n'],
			'c': r['count'],
			'cn': r['count_n']
		})
	vis_data.append(year)

if WRITE_VIS and len(vis_data)>0:
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(vis_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
