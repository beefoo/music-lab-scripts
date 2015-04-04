/*
* Script for playing with adsr
*/

4000 => int interval;

// adsr
ADSR adsr;
200 => int a;
800 => int d;
interval - a - d => int r;
adsr.set( a::ms, d::ms, 0, r::ms );

// reverb
//JCRev rvb;
//NRev rvb;
PRCRev rvb;
0.1 => rvb.mix;

// echo
Echo echo;
0.5 => echo.mix;
500::ms => echo.delay;
1000::ms => echo.max;

// chorus
Chorus chrs;
0.5 => chrs.modFreq;
0.5 => chrs.modDepth;
0.5 => chrs.mix;

// pitch shift
PitShift pts;
0.5 => pts.mix;
0.5 => pts.shift;

// sndbuf
SndBuf instrument;
me.dir() + "/dating/instruments/marvin1a.wav" => instrument.read;
instrument.samples() => instrument.pos;

// instrument => adsr => echo => rvb => dac;
instrument => echo => rvb => chrs => dac;
// instrument => pts => dac;

while(true) {    
    adsr.keyOn();
    0 => instrument.pos;
    1 => instrument.gain;
    1 => instrument.rate;
    interval::ms => now;
    adsr.keyOff();
}


<<< "Done." >>>;

