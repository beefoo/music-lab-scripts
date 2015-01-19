/*
* Script for randomizing instrument samples
*/

// config
1 => int instrument_count;
2000 => int min_duration;
2000 => int max_duration;

// instrument object
class Instrument { 
    string filename;
    SndBuf buf;
}

// define instrument filenames
Instrument instruments[instrument_count];
me.dir() + "/subway/instruments/subway_ding_dong.wav" => instruments[0].filename;

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
        if (coin >= 0) {
            0 => instruments[i].buf.pos;
            0.5 => instruments[i].buf.gain;
            1 => instruments[i].buf.rate;
        }
    }
    Math.random2(min_duration, max_duration)::ms => now;
}


<<< "Done." >>>;

