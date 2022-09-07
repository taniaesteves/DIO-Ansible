#!/bin/bash

LOGS_DIR="final_test_results/ansible_logs"

mkdir -p $LOGS_DIR

RUNS=3

# --------

function reset_kube_cluster {
    ansible-playbook -u gsd -i hosts.ini reset-site.yaml
}

function setup_kube_cluster {
    # reset kubernetes cluster
    reset_kube_cluster

    # create kubernetes cluster
    ansible-playbook -u gsd -i hosts.ini playbook.yml

    # prepare setup
    ansible-playbook -u gsd -i hosts.ini dio_playbook.yml --tags prepare_setup
}

function mount_dio_pipeline {

    # destroy previous dio pipeline
    ansible-playbook -u gsd -i hosts.ini dio_playbook.yml --tags delete_dio -e run_all=true

    # create new dio pipeline
    ansible-playbook -u gsd -i hosts.ini dio_playbook.yml --tags deploy_dio -e run_all=true
}

# --------

function vanilla {
    # reset kubernetes cluster
    reset_kube_cluster

    for ((i=1; i <= $RUNS; i++)); do
        echo "Filebench - Vanilla - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags vanilla -e run_number="$i" | tee "$LOGS_DIR/t00_vanilla_$i.txt" ;
    done
}

function strace {
    # reset kubernetes cluster
    reset_kube_cluster

    for ((i=1; i <= $RUNS; i++)); do
        echo "Filebench - Strace - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags strace -e run_number="$i" | tee "$LOGS_DIR/strace_$i.txt" ;
    done
}

function catbpf {
    reset_kube_cluster

    for ((i=1; i <= $RUNS; i++)); do
        echo "Filebench - catbpf_minhash - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags catbpf_minhash -e run_number="$i" | tee "$LOGS_DIR/catbpf_minhash_$i.txt" ;

        echo "Filebench - catbpf_text - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags catbpf_text -e run_number="$i" | tee "$LOGS_DIR/catbpf_text_$i.txt" ;
    done
}

function old_dio_file {
    # reset kubernetes cluster
    reset_kube_cluster

    for ((i=1; i <= $RUNS; i++)); do
        echo "Filebench - DIO - dio_file_filter_nowait_plain - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags dio_file_filter_nowait_plain -e run_number="$i"  | tee "$LOGS_DIR/dio_file_filter_nowait_plain_$i".txt; # 2>&1 ;

        echo "Filebench - DIO - dio_file_filter_nowait - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags dio_file_filter_nowait -e run_number="$i" | tee "$LOGS_DIR/dio_file_filter_nowait_$i.txt" ;

        echo "Filebench - DIO - dio_file_filter - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags dio_file_filter -e run_number="$i" | tee "$LOGS_DIR/dio_file_filter_$i.txt" ;

        echo "Filebench - DIO - dio_file_all - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags dio_file_all -e run_number="$i" | tee "$LOGS_DIR/dio_file_all_$i.txt" ;
    done
}

# --------

function dio_null {
    # reset kubernetes cluster
    reset_kube_cluster

    mkdir -p $LOGS_DIR

    for ((i=1; i <= $RUNS; i++)); do

        # Run RAW setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-null_"$i"_raw.txt" ;

        # Run DETAILED setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-null_"$i"_detailed.txt" ;

        # Run DETAILED_PATHS setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-null_"$i"_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-null_"$i"_detailed_all.txt" ;

        # RUN DETAILED_ALL_PLAIN setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_detailed_all_plain -e run_number="$i" | tee "$LOGS_DIR/t05_dio-null_"$i"_detailed_all_plain.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-null_"$i"_detailed_all_khash.txt" ;

    done
}

function dio_file {
    # reset kubernetes cluster
    reset_kube_cluster

    mkdir -p $LOGS_DIR

    for ((i=1; i <= $RUNS; i++)); do

        # Run RAW setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-file_"$i"_raw.txt" ;

        # Run DETAILED setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-file_"$i"_detailed.txt" ;

        # Run DETAILED_PATHS setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-file_"$i"_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-file_"$i"_detailed_all.txt" ;

        # RUN DETAILED_ALL_PLAIN setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_all_plain -e run_number="$i" | tee "$LOGS_DIR/t05_dio-file_"$i"_detailed_all_plain.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-file_"$i"_detailed_all_khash.txt" ;

    done
}

function dio_elk {
    mkdir -p $LOGS_DIR

    setup_kube_cluster

    for ((i=1; i <= $RUNS; i++)); do

        # Run RAW setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-1es_"$i"_raw.txt" ;

        # Run DETAILED setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-1es_"$i"_detailed.txt" ;

        # Run DETAILED_PATHS setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-1es_"$i"_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-1es_"$i"_detailed_all.txt" ;

        # RUN DETAILED_ALL_PLAIN setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_all_plain -e run_number="$i" | tee "$LOGS_DIR/t05_dio-1es_"$i"_detailed_all_plain.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-1es_"$i"_detailed_all_khash.txt" ;

    done
}

# --------

function dio_null_profiling {
    # reset kubernetes cluster
    reset_kube_cluster
    mkdir -p /home/gsd/new_profiling_dio_results/

    for ((i=1; i <= $RUNS; i++)); do

        mkdir -p $LOGS_DIR

        # Run RAW setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_profiling_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-null_"$i"_profiling_raw.txt" ;

        # Run DETAILED setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_profiling_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-null_"$i"_profiling_detailed.txt" ;

        # Run DETAILED_PATHS setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_profiling_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-null_"$i"_profiling_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_profiling_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-null_"$i"_profiling_detailed_all.txt" ;

        # RUN DETAILED_ALL_PLAIN setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_profiling_detailed_all_plain -e run_number="$i" | tee "$LOGS_DIR/t05_dio-null_"$i"_profiling_detailed_all_plain.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_null_profiling_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-null_"$i"_profiling_detailed_all_khash.txt" ;

        # Backup results
        sudo cp -r -n final_test_results/* /home/gsd/new_profiling_dio_results/
        sudo rm -fr final_test_results

    done
}

function dio_file_profiling {
    # reset kubernetes cluster
    reset_kube_cluster
    mkdir -p /home/gsd/new_profiling_dio_results/

    for ((i=1; i <= $RUNS; i++)); do

        mkdir -p $LOGS_DIR

        # Run RAW setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_profiling_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-file_"$i"_profiling_raw.txt" ;

        # Run DETAILED setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_profiling_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-file_"$i"_profiling_detailed.txt" ;

        # Run DETAILED_PATHS setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_profiling_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-file_"$i"_profiling_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_profiling_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-file_"$i"_profiling_detailed_all.txt" ;

        # RUN DETAILED_ALL_PLAIN setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_profiling_detailed_all_plain -e run_number="$i" | tee "$LOGS_DIR/t05_dio-file_"$i"_profiling_detailed_all_plain.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_profiling_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-file_"$i"_profiling_detailed_all_khash.txt" ;

        # Backup results
        sudo cp -r -n final_test_results/* /home/gsd/new_profiling_dio_results/
        sudo rm -fr final_test_results

    done
}

function dio_elk_profiling {

    setup_kube_cluster
    mkdir -p /home/gsd/new_profiling_dio_results/

    for ((i=1; i <= $RUNS; i++)); do

        mkdir -p $LOGS_DIR

        # Run RAW setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_profiling_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-1es_"$i"_profiling_raw.txt" ;

        # Run DETAILED setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_profiling_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-1es_"$i"_profiling_detailed.txt" ;

        # Run DETAILED_PATHS setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_profiling_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-1es_"$i"_profiling_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_profiling_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-1es_"$i"_profiling_detailed_all.txt" ;

        # RUN DETAILED_ALL_PLAIN setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_profiling_detailed_all_plain -e run_number="$i" | tee "$LOGS_DIR/t05_dio-1es_"$i"_profiling_detailed_all_plain.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_profiling_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-1es_"$i"_profiling_detailed_all_khash.txt" ;

        # Backup results
        sudo cp -r -n final_test_results/* /home/gsd/new_profiling_dio_results/
        sudo rm -fr final_test_results

    done
}

# --------

function dio_filters {

    setup_kube_cluster

    for ((i=1; i <= $RUNS; i++)); do
        mount_dio_pipeline
        echo "Filebench - DIO - 1 ES, filter tid - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_filter_tid -e run_number="$i" | tee "$LOGS_DIR/t07_dio-1es_"$i"_detailed_filter_tid.txt" ;

        mount_dio_pipeline
        echo "Filebench - DIO - 1 ES, filter orwc - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_filter_orwc -e run_number="$i" | tee "$LOGS_DIR/t08_dio-1es_"$i"_detailed_filter_orwc.txt" ;

        mount_dio_pipeline
        echo "Filebench - DIO - 1 ES, filter read - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_filter_read -e run_number="$i" | tee "$LOGS_DIR/t09_dio-1es_"$i"_detailed_filter_read.txt" ;

        mount_dio_pipeline
        echo "Filebench - DIO - 1 ES, filter stat - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_filter_stat -e run_number="$i" | tee "$LOGS_DIR/t10_dio-1es_"$i"_detailed_filter_stat.txt" ;
    done
}


# vanilla
# old_dio_file
# dio_null
# strace
# catbpf
# dio_elk
# dio_filters

dio_null_profiling
dio_elk_profiling

"$@"