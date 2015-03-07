2000 => int padding;
2 => int instrument_buffers;
0 => int start;

// instrument object
class Instrument { 
    string filename;
    SndBuf buf[8];
    int plays;
}

// data files
me.sourceDir() + "/data/ck_instruments.csv" => string instruments_file;
me.sourceDir() + "/data/ck_sequence.csv" => string sequence_file;

// read data files
FileIO instruments_fio;
FileIO sequence_fio;
instruments_fio.open( instruments_file, FileIO.READ );
sequence_fio.open( sequence_file, FileIO.READ );

// check if files are valid
if( !instruments_fio.good() || !sequence_fio.good() )
{
    cherr <= "can't open instrument and/or sequence files for reading..."
          <= IO.newline();
    me.exit();
}

// create instruments array
Instrument instruments[128];

// read instruments file
while( instruments_fio.more() )
{
    // read instrument index and filename
    Std.atoi(instruments_fio.readLine()) => int instrument_index;
    me.sourceDir() + "/" + instruments_fio.readLine() => instruments[instrument_index].filename;
    0 => instruments[instrument_index].plays;
    // create buffers from filename
    for( 0 => int i; i < instrument_buffers; i++ )
    {
        instruments[instrument_index].filename => instruments[instrument_index].buf[i].read;
        // set position to end, so it won't play immediately upon open
        instruments[instrument_index].buf[i].samples() => instruments[instrument_index].buf[i].pos;
        instruments[instrument_index].buf[i] => dac;
    }
         
}


// Add padding
padding::ms => now;
padding => int elapsed_ms;

// read sequence from file
while( sequence_fio.more() ) {    
    Std.atoi(sequence_fio.readLine()) => int instrument_index;
    Std.atoi(sequence_fio.readLine()) => int position;
    Std.atof(sequence_fio.readLine()) => float gain;
    Std.atof(sequence_fio.readLine()) => float rate;
    Std.atoi(sequence_fio.readLine()) => int milliseconds;
    
    elapsed_ms + milliseconds => elapsed_ms;
    if (start > elapsed_ms)
    {        
        continue;
    }
    
    // wait duration
	if (milliseconds > 0)
    {
        milliseconds::ms => now;
    }
    
    // choose buffer index
    instruments[instrument_index].plays % instrument_buffers => int buffer_index;
    instruments[instrument_index].plays++;
	
    // play the instrument
    position => instruments[instrument_index].buf[buffer_index].pos;
    gain => instruments[instrument_index].buf[buffer_index].gain;
    rate => instruments[instrument_index].buf[buffer_index].rate;
}

// Add padding
padding::ms => now;

<<< "Done." >>>;

