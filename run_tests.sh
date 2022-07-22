#!/bin/bash

mkdir -p ansible_logs

RUNS=3

ansible-playbook -u gsd -i hosts-2es.ini reset-site.yaml

# --------

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - Vanilla - file_vanilla - Run $i"
    ansible-playbook -u gsd filebench_file_playbook.yml  --tags file_vanilla -e run_number="$i" | tee "ansible_logs/file_vanilla_$i.txt" ; #2>&1 ;
done

# --------

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - Strace - file_strace - Run $i"
    ansible-playbook -u gsd filebench_file_playbook.yml  --tags file_strace -e run_number="$i" | tee "ansible_logs/file_strace_$i.txt" ; #2>&1 ;
done

# --------

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - file_catbpf_original_minhash - Run $i"
    ansible-playbook -u gsd filebench_file_playbook.yml  --tags file_catbpf_original_minhash -e run_number="$i" | tee "ansible_logs/file_catbpf_original_minhash_$i.txt" ; #2>&1 ;
done

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - file_catbpf_original_text - Run $i"
    ansible-playbook -u gsd filebench_file_playbook.yml  --tags file_catbpf_original_text -e run_number="$i" | tee "ansible_logs/file_catbpf_original_text_$i.txt" ; #2>&1 ;
done

# --------

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - file_catbpf_new_filter_nowait_plain - Run $i"
    ansible-playbook -u gsd filebench_file_playbook.yml  --tags file_catbpf_new_filter_nowait_plain -e run_number="$i"  | tee "ansible_logs/file_catbpf_new_filter_nowait_plain_$i".txt; # 2>&1 ;
done

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - file_catbpf_new_filter_nowait - Run $i"
    ansible-playbook -u gsd filebench_file_playbook.yml  --tags file_catbpf_new_filter_nowait -e run_number="$i" | tee "ansible_logs/file_catbpf_new_filter_nowait_$i.txt" ; #2>&1 ;
done

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - file_catbpf_new_filter - Run $i"
    ansible-playbook -u gsd filebench_file_playbook.yml  --tags file_catbpf_new_filter -e run_number="$i" | tee "ansible_logs/file_catbpf_new_filter_$i.txt" ; #2>&1 ;
done

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - file_catbpf_new_all - Run $i"
    ansible-playbook -u gsd filebench_file_playbook.yml  --tags file_catbpf_new_all -e run_number="$i" | tee "ansible_logs/file_catbpf_new_all_$i.txt" ; #2>&1 ;
done

# --------

ansible-playbook -u gsd -i hosts-1es.ini playbook.yml
ansible-playbook -u gsd -i hosts-1es.ini cataio_playbook.yml --tags prepare_setup

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - ES=1 - Run $i"
    ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio -e run_number="$i" | tee "ansible_logs/catbpf-1es_$i.txt" ; #2>&1 ;
done

# --------

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - ES=1, filter tid - Run $i"
    ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_filter_tid -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_filter_tid.txt" ; #2>&1 ;
done

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - ES=1, filter stat - Run $i"
    ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_filter_stat -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_filter_stat.txt" ; #2>&1 ;
done

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - ES=1, filter read - Run $i"
    ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_filter_read -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_filter_read.txt" ; #2>&1 ;
done

# --------

ansible-playbook -u gsd -i hosts-1es.ini reset-site.yaml
ansible-playbook -u gsd -i hosts-2es.ini playbook.yml
ansible-playbook -u gsd -i hosts-2es.ini cataio_playbook.yml --tags prepare_setup

for ((i=1; i <= $RUNS; i++)); do
    echo "Filebench - CatBpf - ES=2 - Run $i"
    ansible-playbook -u gsd -i hosts-2es.ini filebench_cataio_playbook.yml --tags cataio -e run_number="$i" | tee "ansible_logs/catbpf-2es_$i.txt" ; #2>&1 ;
done



# --------

# for ((i=1; i <= $RUNS; i++)); do
#     echo "Filebench - CatBpf - ES=1 - Run $i, FB=30MB, FI=600s PROF_TIMES"
#     ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_fb_30mb -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_fb_30mb_times.txt" ; #2>&1 ;
#     # echo "Filebench - CatBpf - ES=2 - Run $i, FB=30MB, FI=600s PROF_TIMES"
#     # ansible-playbook -u gsd -i hosts-2es.ini filebench_cataio_playbook.yml --tags cataio_fb_30mb -e run_number="$i" | tee "ansible_logs/catbpf-2es_"$i"_fb_30mb_times.txt" ; #2>&1 ;

#     # echo "Filebench - CatBpf - ES=1 - Run $i, FB=10MB, FI=600s"
#     # ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_fb_10mb_10min -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_fb_10mb_10min.txt" ; #2>&1 ;

#     # echo "Filebench - CatBpf - ES=1 - Run $i, FB=5MB, FI=600s PROF_TIMES"
#     # ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_fb_5mb -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_fb_5mb_times.txt" ; #2>&1 ;

# done

# ansible-playbook -i hosts-1es.ini -u gsd rocksdb_cataio_playbook.yml --tags destroy_cataio_pipeline #> /dev/null  2>&1

# sudo rm -fr ~/tests_rocksdb/ > /dev/null  2>&1

# echo "RocksDB - Load"
# ansible-playbook -i hosts-1es.ini -u gsd rocksdb_cataio_playbook.yml --tags load | tee "ansible_logs/rocksdb_load.txt" # 2>&1 ;

# for ((i=1; i <= $RUNS; i++)); do

#     # ansible-playbook -i hosts-1es.ini -u gsd rocksdb_cataio_playbook.yml --tags destroy_cataio_pipeline > /dev/null  2>&1
#     # docker rm  tests_rocksdb_vanilla_rocksdb_1 > /dev/null  2>&1
#     # echo "RocksDB - Vanilla - Run $i"
#     # ansible-playbook  -i hosts-1es.ini -u gsd rocksdb_cataio_playbook.yml --tags vanilla -e run_number="$i" | tee "ansible_logs/rocksdb_vanilla_run$i.txt" ; #2>&1 ;

#     docker rm  tests_rocksdb_catbpf_rocksdb_1 > /dev/null  2>&1
#     echo "RocksDB - CatBpf  - Run $i - 1 ES"
#     ansible-playbook  -i hosts-1es.ini -u gsd rocksdb_cataio_playbook.yml --tags catbpf -e run_number="$i" | tee "ansible_logs/rocksdb_catbpf_1es_run$i.txt" # 2>&1 ;

#     # docker rm  tests_rocksdb_strace_rocksdb_1 > /dev/null  2>&1
#     # echo "RocksDB - Strace - Run $i"
#     # ansible-playbook  -i hosts-1es.ini -u gsd rocksdb_cataio_playbook.yml --tags strace -e run_number="$i" | tee "ansible_logs/rocksdb_strace_run$i.txt" ; #2>&1 ;

# done


# --------

# for ((i=1; i <= $RUNS; i++)); do
#     echo "Filebench - CatBpf - ES=1 - Run $i, FB=4MB, FI=30s"
#     ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_fb_4mb -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_fb_4mb.txt" ; #2>&1 ;
# done

# for ((i=1; i <= $RUNS; i++)); do
#     echo "Filebench - CatBpf - ES=1 - Run $i, FB=7000000, FI=60s"
#     ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_fi_1m -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_f1_1m.txt" ; #2>&1 ;
# done

# for ((i=1; i <= $RUNS; i++)); do
#     echo "Filebench - CatBpf - ES=1 - Run $i, FB=10MB, FI=30s"
#     ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_fb_10mb -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_fb_10mb.txt" ; #2>&1 ;
# done

# for ((i=1; i <= $RUNS; i++)); do
#     echo "Filebench - CatBpf - ES=1 - Run $i, FB=100MB, FI=600s"
#     ansible-playbook -u gsd -i hosts-1es.ini filebench_cataio_playbook.yml --tags cataio_fb_100mb -e run_number="$i" | tee "ansible_logs/catbpf-1es_"$i"_fb_100mb.txt" ; #2>&1 ;
# done
