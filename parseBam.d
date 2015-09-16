// run example: rdmd -IBioD parseBam

import std.parallelism; 
import std.stdio; 
import std.getopt; 
import bio.bam.reader; 
import bio.bam.writer;


void printUsage() {         //prints usage statement
    stderr.writeln("Usage: parseBam.d [options]");
    stderr.writeln();
    stderr.writeln("Options: -i, --input bam");
    stderr.writeln("                    (required) specify input file");
    stderr.writeln("         -o, --output bam [stdout]");
    stderr.writeln("                    specify output file");
    stderr.writeln("         -t, --threads [numCPUs]");
    stderr.writeln("                    specify number of threads");
    stderr.writeln("         -l, --level (0-9) [9]");
    stderr.writeln("                    specify BAM compression level");

}

int main(string[] args) {

    string input = null;
    string output = "/dev/stdout";
    int compression_level = 9;
    int n_threads = totalCPUs;

    try {
        getopt(args,std.getopt.config.caseSensitive,
               "input|i",            &input,
               "output|o",           &output,
               "threads|t",          &n_threads,
               "level|l",            &compression_level);
    } catch {printUsage(); return 0;}

    if (args.length < 1 || input == null) {printUsage(); return 0;}

	auto pool = new TaskPool(n_threads);
	scope (exit) pool.finish();

    auto in_bam = new BamReader(input, pool);

    auto out_bam = new BamWriter(output, compression_level, pool);
    scope (exit) out_bam.finish();

    out_bam.disableAutoIndexCreation();
    out_bam.writeSamHeader(in_bam.header);
    out_bam.writeReferenceSequenceInfo(in_bam.reference_sequences);
                                      
    foreach (read; in_bam.reads) {

        if(read.is_secondary_alignment || read.is_duplicate) {

            continue;

        } else if( (to!int(read["AS"]) == to!int(read["XS"])) || read.mapping_quality == 0) {

    		read["X0"] = 3;

    	} else {

            read["X0"] = 1;

        }

    	out_bam.writeRecord(read);

    }

    return 0;

}




