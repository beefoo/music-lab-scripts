2000 => int padding;

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

// create instruments from file
SndBuf instruments[120];
while( instruments_fio.more() )
{
    Std.atoi(instruments_fio.readLine()) => int instrument_index;
    me.sourceDir() + "/" + instruments_fio.readLine() => string filename;    
    filename => instruments[instrument_index].read;
    // set position to end, so it won't play immediately upon open
    instruments[instrument_index].samples() => instruments[instrument_index].pos;
    instruments[instrument_index] => dac;
}

// Add padding
padding::ms => now;

// read sequence from file
while( sequence_fio.more() ) {    
    Std.atoi(sequence_fio.readLine()) => int instrument_index;
    Std.atoi(sequence_fio.readLine()) => int position;
    Std.atof(sequence_fio.readLine()) => float gain;
    Std.atof(sequence_fio.readLine()) => float rate;
    Std.atoi(sequence_fio.readLine()) => int milliseconds;
    
	if (milliseconds > 0)
    {
        milliseconds::ms => now;
    }
	
    position => instruments[instrument_index].pos;
    gain => instruments[instrument_index].gain;
    rate => instruments[instrument_index].rate;
}

// Add padding
padding::ms => now;

<<< "Done." >>>;

