mkdir -p summary
python /Project/SGT/rpdSeqdev/SGT1040/do_summary/get_summary.py -c /Project/SGT/rpdSeqdev/SGT1040/do_summary/fastp_column_config.yaml -i CleanData/json -o ./summary
echo "library_id,batch_id,host_ratio" > ./summary/host_ratio.csv
grep overall AlignHost/summary/* | sed 's#/#\t#g' | cut -f 3 | sed 's/-/\t/' | sed 's/.summary:/\t/' | sed 's/%/\t/' | cut -f 1-3 | sed 's/\t/,/g' >> ./summary/host_ratio.csv
echo "library_id,batch_id,rRNA_ratio" > ./summary/rRNA_ratio.csv
grep overall RemoveRrna/summary/* | sed 's#/#\t#g' | cut -f 3 | sed 's/-/\t/' | sed 's/.summary:/\t/' | sed 's/%/\t/' | cut -f 1-3 | sed 's/\t/,/g' >> ./summary/rRNA_ratio.csv
python /Project/SGT/rpdSeqdev/SGT1040/get_score/get_score.py --ends itemstat.csv \
    --fastp ./summary/fastp_summary.csv --in ./ItemStat --norm after-total_reads \
    --out ./summary/score --sc /Project/SGT/rpdSeqdev/SGT1040/get_score/score.yaml \
    --sp /Project/SGT/rpdSeqdev/SGT1040/get_score/ncov.yaml \
    --host ./summary/host_ratio.csv --rrna ./summary/rRNA_ratio.csv
