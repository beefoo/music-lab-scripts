# -*- coding: utf-8 -*-

from bs4 import BeautifulSoup
import json
import pprint

input_file = "files/albums.html"
output_file = "data/albums.json"

html_content = ""
albums = []

with open (input_file, "r") as f:
    html_content = f.read().replace('\n','')

soup = BeautifulSoup(html_content, 'html.parser')

# Retrieve album names and urls
for artist in soup.find_all("div", class_="artist"):
    artist_name = artist.get('title')
    items = artist.find_all("a")
    for item in items:
        url = "http://genius.com" + item.get('href')
        albums.append({
            "artist": artist_name,
            "album": item.string.strip(),
            "url": url
        })

# Save albums
with open(output_file, 'w') as f:
    json.dump(albums, f)
    print('Successfully wrote to JSON file: '+output_file)
