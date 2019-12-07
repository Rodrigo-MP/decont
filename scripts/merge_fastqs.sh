# This script should merge all files from a given sample (the sample id is provided in the third argument)
# into a single file, which should be stored in the output directory specified by the second argument.
# The directory containing the samples is indicated by the first argument.
sampleid=$3
cat $1/${sampleid}*.fastq.gz > $2/${sampleid}.merged.tar.gz
