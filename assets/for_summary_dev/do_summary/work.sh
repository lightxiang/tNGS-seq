grep overall ../AlignHost/summary/* | sed 's#/#	#g' | sed 's#:#	#' | cut -f 4,5 > host_ratio.txt
grep overall ../RemoveRrna/summary/* | sed 's#/#	#g' | sed 's#:#	#' | cut -f 4,5 > rRNA_ratio.txt 
python get_summary.py -c ./fastp_column_config.yaml -i ../CleanData/json -o ./
python pandas_json2csv.py
