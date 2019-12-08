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
for sid in $(ls data/*.fastq.gz | cut -d"-" -f1 | sed "s:data/::" | sort | uniq)
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# run cutadapt for all merged files
echo "Running cutadapt..."
mkdir -p log/cutadapt
mkdir -p out/trimmed
for sid in $(ls out/merged/*.tar.gz | cut -d"." -f1 | sed "s:out/merged/::" | sort | uniq)
do
  cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed -o out/trimmed/${sid}.trimmed.fastq.gz out/merged/${sid}.merged.tar.gz > log/cutadapt/${sid}.log
done

#run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=$(basename $fname | cut -d "." -f1 | sort | uniq)
    mkdir -p out/star/$sid
    STAR --runThreadN 4 --genomeDir res/contaminants_idx --outReadsUnmapped Fastx --readFilesIn $fname --readFilesCommand zcat --outFileNamePrefix out/star/$sid
done

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
cd $WD
echo "Log que contiene información de la eliminación de los procesos cutadapt y STAR" >> log.out
for sid in $(ls out/merged/*.tar.gz | cut -d"." -f1 | sed "s:out/merged/::" | sort | uniq)
do
  echo "Cutadapt de ${sid}: Reads with adapters and total basepairs" >> log.out
  head -9 log/cutadapt/${sid}.log | tail -1 >> log.out
  head -13 log/cutadapt/${sid}.log | tail -1 >> log.out
  # - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
  echo "STAR de ${sid}: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci" >> log.out
  head -10 out/star/${sid}/Log.final.out | tail -1 >> log.out
  head -25 out/star/${sid}/Log.final.out | tail -1 >> log.out
  head -27 out/star/${sid}/Log.final.out | tail -1 >> log.out
done
