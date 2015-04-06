/*
* Script for playing with adsr
*/

4000 => int interval;

// adsr
ADSR adsr;
200 => int a;
1000 => int d;
0 => float s;
interval - a - d => int r;
adsr.set( a::ms, d::ms, s, r::ms );

// reverb
//JCRev rvb;
//NRev rvb;
PRCRev rvb;
0.3 => rvb.mix;

// echo
Echo echo;
0.5 => echo.mix;
500::ms => echo.delay;
1000::ms => echo.max;

// chorus
Chorus chrs;
0.2 => chrs.modFreq;
0.2 => chrs.modDepth;
0.5 => chrs.mix;

// pitch shift
PitShift pts;
0.7 => pts.mix;
0.5 => pts.shift;

// sndbuf
SndBuf instrument;
me.dir() + "/dating/instruments/strings2b.wav" => instrument.read;
instrument.samples() => instrument.pos;

instrument => adsr => echo => rvb => dac;
// instrument => adsr => rvb => dac;
// instrument => echo => rvb => chrs => dac;
// instrument => pts => rvb => dac;
// instrument => chrs => dac;
// instrument => echo => dac;
// instrument => dac;

while(true) {    
    adsr.keyOn();
    0 => instrument.pos;
    1 => instrument.gain;
    1 => instrument.rate;
    interval::ms => now;
    adsr.keyOff();
}


<<< "Done." >>>;

