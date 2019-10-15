#!/bin/bash

#conda activate bioawk

#wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/protozoa/assembly_summary.txt | tail -n +3 > assembly_summary.txt
#wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/fungi/assembly_summary.txt | tail -n +3 >> assembly_summary.txt
#wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/viral/assembly_summary.txt | tail -n +3 >> assembly_summary.txt
#wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/archaea/assembly_summary.txt | tail -n +3 >> assembly_summary.txt
#wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/assembly_summary.txt | tail -n +3 >> assembly_summary.txt



#mkdir other
#download other stuff
#wget -O - ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/plasmid/plasmid.*.genomic.fna.gz >> Plasmids.fna.gz
#wget -O Univec_Core.fa ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec_Core
#wget ftp://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.fa.gz


download_link () {

ftp_path=$(awk -F '\t' '{print $20}' $1)
base_name=$(echo "$ftp_path" | awk -F '/' '{print $10}')
fullpath=$(echo "$ftp_path""/""$base_name""_genomic.fna.gz")

while [ 1 ]; do
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 --continue "$fullpath"
    if [ $? = 0 ]; then break; fi; # check return value, break if successful (0)
    sleep 1s;
done;
}

download_largest () {

IFS='
'
while read x || [[ -n $x ]]; do


ftp_path=$(echo $x | awk -F '\t' '{print $20}')
#echo $ftp_path
base_name=$(echo "$ftp_path" | awk -F '/' '{print $10}')
fullpath=$(echo "$ftp_path""/""$base_name""_assembly_stats.txt")

while [ 1 ]; do
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 --continue "$fullpath"
    if [ $? = 0 ]; then break; fi; # check return value, break if successful (0)
    sleep 1s;
done

done <$1

acc=$(awk '($1=="all" && $5=="total-length"){print FILENAME, $6}' *_assembly_stats.txt | sort -rn -k2 | cut -f1 -d' ' | head -n1)
acc=${acc::-19}

grep $acc $1 | head -n1 > largest.txt

download_link largest.txt

}

download_representative () {
awk -F '\t' '($5=="representative genome"){print $0}' $1 > representative.txt
rep_count=$(wc -l representative.txt | cut -f1 -d' ')

if (( rep_count ==1 )); then
        download_link representative.txt
elif ((rep_count > 1 )); then
	download_largest representative.txt
else
	download_reference $1
fi
}

download_reference () {
awk -F '\t' '($5=="reference genome"){print $0}' $1 > reference.txt

ref_count=$(wc -l reference.txt | cut -f1 -d' ')

if (( ref_count == 1 )); then
        download_link reference.txt
elif ((ref_count > 1 )); then
	download_complete reference.txt
else
	download_complete $1
fi
}

download_complete () {
awk -F '\t' '($12=="Complete Genome"){print $0}' $1 > complete.txt
complete_count=$(wc -l complete.txt | cut -f1 -d' ')
if (( complete_count == 1 )); then
	download_link complete.txt
elif (( complete_count > 1)); then	
	download_largest complete.txt
else
	download_chromosome $1
fi
}

download_chromosome () {
awk -F '\t' '($12=="Chromosome"){print $0}' $1 > chromosome.txt
chromosome_count=$(wc -l chromosome.txt | cut -f1 -d' ')

if (( chromosome_count == 1 )); then
	download_link chromosome.txt
elif (( chromosome_count > 1 )); then
	download_largest chromosome.txt
else
	download_scaffold $1
fi

}

download_scaffold () {
awk -F '\t' '($12=="Scaffold"){print $0}' $1 > scaffold.txt
scaffold_count=$(wc -l scaffold.txt | cut -f1 -d' ')

if (( scaffold_count == 1 )); then
	download_link scaffold.txt
elif (( scaffold_count > 1 )); then
	download_largest scaffold.txt
else
	download_contig $1

fi
}

download_contig () {
awk -F '\t' '($12=="Contig"){print $0}' $1 > contig.txt
contig_count=$(wc -l contig.txt | cut -f1 -d' ')

if (( contig_count == 1 )); then
	download_link contig.txt
elif (( contig_count > 1 )); then
	download_largest contig.txt
else
	echo "tax ID without fasta!"
	cat $1 >> ../errors.txt
	exit 1
fi
}


#find representative genomes

#Unique taxids


p=$1

	mkdir "$p"
	cd $p
	awk -F '\t' -v taxid=$p '($7==taxid){print $0}' ../assembly_summary.txt > genomes.txt 
	genome_count=$(wc -l genomes.txt | cut -f1 -d' ')
	
	if (( genome_count == 1 )); then

		download_link genomes.txt

#If there's more than one genome for the tax ID, need to pick one. First pick representative, if none available, then reference, then largest most complete (ie Complete > Scaffold > Contig) and second sort by size within each

	else
		download_representative genomes.txt

	fi
species_name=$(awk -v taxid=$p -F'\t' '($7==taxid){print $8}' ../assembly_summary.txt | head -n1 | sed 's/ /_/g')
bioawk -c fastx '{ if(length($seq) > 999) { print ">"$name; print $seq }}' *.fna.gz | bioawk -v taxid=$p -v species=$species_name -c fastx 'BEGIN{s=sprintf("%100s","");gsub(/ /,"N",s);print ">" taxid "_" species} (NR==1){printf $seq} (NR>1){printf s $seq}' | gzip > '../genomes/'$p'.fna.gz'
cd ..
rm -rf $p




