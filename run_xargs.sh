mkdir genomes


wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/protozoa/assembly_summary.txt | tail -n +3 > assembly_summary.txt
wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/fungi/assembly_summary.txt | tail -n +3 >> assembly_summary.txt
wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/viral/assembly_summary.txt | tail -n +3 >> assembly_summary.txt
wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/archaea/assembly_summary.txt | tail -n +3 >> assembly_summary.txt
wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/assembly_summary.txt | tail -n +3 >> assembly_summary.txt



mkdir other
#download other stuff
wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/plasmid/plasmid.*.genomic.fna.gz >> other/Plasmids.fna.gz
wget -O other/Univec_Core.fa ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec_Core
wget -O other/hg38.fa.gz ftp://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.fa.gz


cut -f7 assembly_summary.txt | sort -u > taxids.txt
cat taxids.txt | xargs -n 1 -P 20 ./xarg_custom_reprDB_all.sh
