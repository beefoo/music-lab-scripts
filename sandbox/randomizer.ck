/*
* Script for randomizing instrument samples
*/

// config
4 => int instrument_count;
200 => int min_duration;
800 => int max_duration;

// instrument object
class Instrument { 
    string filename;
    SndBuf buf;
}

// define instrument filenames
Instrument instruments[instrument_count];
me.dir() + "/subway/instruments/diner_vocals_05.wav" => instruments[0].filename;
me.dir() + "/subway/instruments/nocturne_horn_02.wav" => instruments[1].filename;
me.dir() + "/subway/instruments/counterpoint_clarinet_01.wav" => instruments[2].filename;
me.dir() + "/subway/instruments/rhapsody_piano_01.wav" => instruments[3].filename;

// load instruments into sound buffers
for( 0 => int i; i < instrument_count; i++ )
{    
    instruments[i].filename => instruments[i].buf.read;
    // set position to end, so it won't play immediately upon open
    instruments[i].buf.samples() => instruments[i].buf.pos;
    instruments[i].buf => dac;
}

// loop and play instruments
while(true) {
    for( 0 => int i; i < instrument_count; i++ )
    { 
        Math.random2(0, 1) => int coin;
        if (coin > 0) {
            0 => instruments[i].buf.pos;
            0.5 => instruments[i].buf.gain;
            1 => instruments[i].buf.rate;
        }
    }
    Math.random2(min_duration, max_duration)::ms => now;
}


<<< "Done." >>>;

