Data-Driven DJ Track 1: Two Trains
=================

You can listen to this track and read the full description [here](https://datadrivendj.com/tracks/subway).

## Software Required

All software required for making this song from scratch is free and open-source

* [ChucK](http://chuck.cs.princeton.edu/) - a programming language for real-time sound synthesis and music creation
* [Python](https://www.python.org/) - I am running version 2.7.3
* [Processing](https://processing.org/) - optional, for supporting visualization

## Instructions

### Prepare Your Data And Sound Files

1. Create a tab-delimited stations.csv file based on [stations.csv.sample](data/stations.csv.sample) file and place in folder `/data`
  * **Month Income** column is what is being used by the script as the "budget" of the station
  * **Latitude** and **Longitude** are being used to determine the distance between stations
2. Create a tab-delimited instruments.csv file based on [instruments.csv.sample](data/instruments.csv.sample) file and place in folder `/data`
  * **Price** column is what the station uses to determine what instruments it can afford based on its **Month Income** column from stations.csv
  * **Bracket Min** and **Bracket Max** is the income bracket range this instrument is valid for. For example if **Bracket Min** equals 90, only the top 10% based on median income can use this instrument.
  * **File** is the filename of the instruments sound file
  * **From Gain** and **To Gain** is the volume range this instrument can oscillate between. A value of 0 is silent.
  * **From Tempo** and **To Tempo** is the tempo range this instrument can oscillate bewteen. A value of 1 is standard BPM, 2 is twice as fast, 0.5 is twice as slow.
  * **Gain Phase** is the number of beats that represent a full phase of an instrument's gain range. For example, if the gain phase is 16, gain min is 0, and gain max is 1, it will take 16 beats to go from 0 gain to 1 gain back to 0 gain.
  * **Gain Tempo** is the number of beats that represent a full phase of an instrument's tempo range. For example, if the tempo phase is 16, tempo min is 1, and tempo max is 2, it will take 16 beats to go from a tempo of 1 to a tempo of 2 back to a tempo of 1.
  * **Interval Phase**, **Interval**, **Interval Offset** control at what intervals the instruments can play. For example, if interval phase is 16, interval is 2, and interval offset is 1, every 16 beats, the instrument can play on the 2nd half of the beats (8-16).
  * **Active** essentially activates or deactivates an instrument
3. Prepare all your sound files and place in folder `/instruments`. All files should be in .wav format. For best results, I'd recommend using very short clips (< 500ms).
  
### Configure The Scripts

1. Python script: [subway.py](subway.py)
  * **BPM** is the song's beats per minute. I'd recommend using 60, 75, 100, 120, or 150. You will otherwise run the risk of having rounding errors caused by flaws in this script--sorry!
  * **METERS_PER_BEAT** is the amount of meters per beat. In general, the higher this number, the shorter the song.
  * **DIVISIONS_PER_BEAT** is how the beats are divided. For example, a value of 4 would create quarter-notes as the smallest unit, 8 would create eighth-notes, etc.
2. ChucK script: [subway.ck](subway.ck)
  * **padding** is the amount of milliseconds before and after the song.
  * **instrument_buffers** is the number of buffers each instrument has. If you hear clipping in your song, you will want to increase this number.

### Generating The Song

1. Run `python subway.py` in the project's directory. This will generate two files that ChucK will use:
  * `data/ck_instruments.csv`: A manifest of instrument files
  * `data/ck_sequence.csv`: A sequence of instruments
2. Open up **subway.ck** in ChucK. You can either export the song to .ogg/.wav or start your VM and add a new shred

### Generating The Visualization

1. Open [visualization/stations/stations.pde](visualization/stations/stations.pde) in Processing. This script generates a scrolling station visualization.
  * this script uses data (stations.json) generated from previous python script
  * set `boolean captureFrames = true;` to output frames to output folder
  * run script, this will generate frames at the framerate (`fps`) in the configuration.
2. Open [visualization/map/map.pde](visualization/map/map.pde) in Processing. This script generates a map showing the train's progress.
  * this script uses data (stations.json) generated from previous python script
  * set `boolean captureFrames = true;` to output frames to output folder
  * run script, this will generate frames at the framerate (`fps`) in the configuration.