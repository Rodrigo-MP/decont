# This script should download the file specified in the first argument ($1), place it in the directory specified in the second argument,
# and *optionally* uncompress the downloaded file with gunzip if the third argument contains the word "yes".
wget -P $2 $1
if ["$3" == "yes"]
  do
    cd $WD
    cp ./data/*.gz $4
    gunzip -C -k ./data/*.gz > basename ./data/*.gz .gz
    gunzip -k ./res/*.gz
  done
