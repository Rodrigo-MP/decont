#Download all the files specified in data/urls

cd ~/github/decont
pwd
export WD=$(pwd)
echo $WD
cd $WD
URLS="~/github/decont/data/urls"
for url in $(cat $URLS)
    do
      bash scripts/download.sh $url data
    done

# Download the contaminants fasta file, and uncompress it
cd $WD
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes

# Index the contaminants file
cd $WD
mkdir res/contaminants_idx
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx/

# Merge the samples into a single file
IDS="~/github/decont/data"
for sid1 in C57BL_6NJ
do
    bash scripts/merge_fastqs.sh data out/merged $sid1
done
for sid2 in SPRET_EiJ
do
    bash scripts/merge_fastqs.sh data out/merged $sid2
done

# run cutadapt for all merged files
echo "Running cutadapt..."
mkdir -p log/cutadapt
mkdir -p out/trimmed
cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed -o out/trimmed/${sid1}.trimmed.fastq.gz /home/rodrigo/github/decont/out/merged/${sid1}.merged.tar.gz > log/cutadapt/${sid1}.log
cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed -o out/trimmed/${sid2}.trimmed.fastq.gz /home/rodrigo/github/decont/out/merged/${sid2}.merged.tar.gz > log/cutadapt/${sid2}.log

#run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=$(basename $fname | cut -d "." -f1 | sort | uniq)
    mkdir -p out/star/$sid
    STAR --runThreadN 4 --genomeDir res/contaminants_idx --outReadsUnmapped Fastx --readFilesIn $fname --readFilesCommand zcat --outFileNamePrefix out/star/$sid
done

# TODO: create a log file containing information from cutadapt and star logs
cd $WD
cat ~/github/decont/log/cutadapt/* ~/github/decont/out/star/C57BL_6NJ/*Log* ~/github/decont/out/star/SPRET_EiJ/*Log* > log.out
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
