#!/bin/bash
set -ex

rm -f pubmed_listing.txt pmc_listing.txt

echo "Updating PubMed and PubMed Central (Open Access / Author Manuscript) listings"

for dir in "baseline" "updatefiles"
do
	ftpPath=ftp://ftp.ncbi.nlm.nih.gov/pubmed/$dir/

	curl --silent $ftpPath |\
	grep -oP "pubmed\w+.xml.gz" |\
	sort -u |\
	awk -v ftpPath=$ftpPath ' { print ftpPath$0 } ' >> pubmed_listing.txt
done

for ftpPath in "ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/oa_bulk/" "ftp://ftp.ncbi.nlm.nih.gov/pub/pmc/manuscript/"
do
	curl --silent $ftpPath |\
	grep -oP "\S+.xml.tar.gz" |\
	sort -u |\
	awk -v ftpPath=$ftpPath ' { print ftpPath$0 } ' >> pmc_listing.txt
done

mkdir -p pmc_archives
cd pmc_archives

rm -f download.tmp

#for f in `echo $files | tr ',' '\n'`
while read ftpPath
do
	f=`echo $ftpPath | grep -oP "[^/]+$"`

	timestamp="Wed, 31 Dec 1969 16:00:00 -0800"
	if [ -f $f ]; then
		timestamp=`date -R -d @$(stat -c '%Y' $f)`
	fi

	curl -o download.tmp $ftpPath --time-cond "$timestamp"
	if [ -f download.tmp ]; then
		mv download.tmp $f
	fi

done < ../pmc_listing.txt

python ../groupPMC.py --inPMCDir . --prevGroupings groupings.json.prev --outGroupings groupings.json

cp groupings.json groupings.json.prev

