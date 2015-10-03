# -*- coding: utf-8 -*-

from bs4 import BeautifulSoup
import json
import pprint

albums_file = "data/albums.json"
album_dir = "files/albums/"
output_file = "data/songs.json"

albums = []
songs = []

# Read categories
with open(albums_file) as f:
    albums = json.load(f)

for album in albums:
    filename = album_dir + album["url"].split("/")[-1] + ".htm"
    html_content = ""
    with open (filename, "r") as f:
        html_content = f.read().replace('\n','')
    soup = BeautifulSoup(html_content, 'html.parser')

    # retrieve album year
    album_year = soup.find("span", class_="release_year").string
    if album_year:
        album_year = int(album_year.strip().replace("(","").replace(")",""))
    else:
        print "No year found for " + album["album"]

    # Retrieve songs
    songlist = soup.find("ul", class_="primary_list")
    for link in songlist.find_all("a", class_="song_link"):
        title = link.find("span", class_="song_title").string.strip()
        songs.append({
            "artist": album["artist"],
            "gender": album["gender"],
            "album": album["album"],
            "year": album_year,
            # "album_url": album["url"],
            "url": link.get('href'),
            "title": title
        })

# Save songs
with open(output_file, 'w') as f:
    json.dump(songs, f)
    print('Successfully wrote ' + str(len(songs)) + ' songs to JSON file: '+output_file)
