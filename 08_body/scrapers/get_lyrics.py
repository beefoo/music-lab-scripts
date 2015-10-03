# -*- coding: utf-8 -*-

from bs4 import BeautifulSoup
import json
import pprint
import re

songs_file = "data/songs.json"
songs_dir = "files/songs/"
output_file = "../data/lyrics.json"

songs = []
song_lyrics = []

# Read categories
with open(songs_file) as f:
    songs = json.load(f)

for song in songs:
    filename = songs_dir + song["url"].split("/")[-1] + ".htm"
    if song['artist'].lower().replace(' ','-').replace('é'.decode('utf-8'),'e') not in song['url'].lower() or '[Credits]' in song['title']:
        print "Skipping: " + song["url"]
        continue
    print "Parsing " + song["title"] + "..."
    html_content = ""
    with open (filename, "r") as f:
        html_content = f.read().replace('\n','')
    soup = BeautifulSoup(html_content, 'html.parser')

    # Retrieve song lyrics
    container = soup.find("div", class_="lyrics_container")
    content = container.find("div", class_="lyrics")
    lyrics =  " ".join(content.strings).lower().replace('\n',' ') # remove newline
    lyrics = re.sub('[^a-z\- ]|\-\-', ' ', lyrics) # remove punctuation
    lyrics = ' '.join(lyrics.split()) # remove multi-space
    song_lyrics.append({
        "artist": song["artist"],
        "gender": song["gender"],
        "album": song["album"],
        "song": song["title"],
        "year": song["year"],
        "url": song["url"],
        "lyrics": lyrics
    })

# Save song lyrics
with open(output_file, 'w') as f:
    json.dump(song_lyrics, f)
    print('Successfully wrote ' + str(len(song_lyrics)) + ' songs to JSON file: '+output_file)
