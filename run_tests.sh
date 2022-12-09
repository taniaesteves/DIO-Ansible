#!/bin/bash

LOGS_DIR="final_test_results/ansible_logs"

mkdir -p $LOGS_DIR

STARTING_RUN=1
RUNS=3


# --------

function reset_kube_cluster {
    ansible-playbook -u gsd -i hosts.ini reset-site.yaml

    if [ $? -eq 0 ]; then
        echo OK
    else
        ansible-playbook -u gsd -i hosts.ini reset-site.yaml
        if [ $? -eq 0 ]; then
            echo OK
        else
            echo "FAILED to create the cluster"
            exit 1
        fi
    fi


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
    FILEBENCH_RATE_LIMITE=$1
    FILEBENCH_EVENT_GEN_RATE=$2

    sufix=""
    if [ "$FILEBENCH_RATE_LIMITE" == "true" ]; then
        sufix="_rate_limited_"$FILEBENCH_EVENT_GEN_RATE
    fi

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do
        echo "Filebench - Vanilla - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags vanilla -e run_number="$i" -e filebench_rate_limit=$FILEBENCH_RATE_LIMITE -e filebench_event_rate=$FILEBENCH_EVENT_GEN_RATE | tee "$LOGS_DIR/t00_vanilla_$i$sufix.txt" ;
    done
}

function strace {
    # reset kubernetes cluster
    reset_kube_cluster

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do
        echo "Filebench - Strace - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags strace -e run_number="$i" | tee "$LOGS_DIR/strace_$i.txt" ;
    done
}

function catbpf {
    reset_kube_cluster

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do
        echo "Filebench - catbpf_minhash - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags catbpf_minhash -e run_number="$i" | tee "$LOGS_DIR/catbpf_minhash_$i.txt" ;

        echo "Filebench - catbpf_text - Run $i"
        ansible-playbook -u gsd filebench_playbook.yml  --tags catbpf_text -e run_number="$i" | tee "$LOGS_DIR/catbpf_text_$i.txt" ;
    done
}

function old_dio_file {
    # reset kubernetes cluster
    reset_kube_cluster

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do
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

function dio_file {
    # reset kubernetes cluster
    reset_kube_cluster

    mkdir -p $LOGS_DIR

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do

        # Run RAW setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-file_"$i"_raw.txt" ;

        # Run DETAILED setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-file_"$i"_detailed.txt" ;

        # # Run DETAILED_PATHS setup
        # ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-file_"$i"_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-file_"$i"_detailed_all.txt" ;

        # RUN DETAILED_ALL_UHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_all_uhash -e run_number="$i" | tee "$LOGS_DIR/t05_dio-file_"$i"_detailed_all_uhash.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-file_"$i"_detailed_all_khash.txt" ;

    done
}

function dio_elk {
    mkdir -p $LOGS_DIR
    FILEBENCH_RATE_LIMITE=$1
    FILEBENCH_EVENT_GEN_RATE=$2

    sufix=""
    if [ "$FILEBENCH_RATE_LIMITE" == "true" ]; then
        sufix="_rate_limited_"$FILEBENCH_EVENT_GEN_RATE
    fi

    setup_kube_cluster

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do

        # Run RAW setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_raw -e run_number="$i" -e filebench_rate_limit=$FILEBENCH_RATE_LIMITE -e filebench_event_rate=$FILEBENCH_EVENT_GEN_RATE | tee "$LOGS_DIR/t01_dio-1es_"$i"_raw$sufix.txt" ;

        # Run DETAILED setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed -e run_number="$i" -e filebench_rate_limit=$FILEBENCH_RATE_LIMITE -e filebench_event_rate=$FILEBENCH_EVENT_GEN_RATE | tee "$LOGS_DIR/t02_dio-1es_"$i"_detailed$sufix.txt" ;

        # # Run DETAILED_PATHS setup
        # mount_dio_pipeline
        # ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_paths -e run_number="$i" -e filebench_rate_limit=$FILEBENCH_RATE_LIMITE -e filebench_event_rate=$FILEBENCH_EVENT_GEN_RATE | tee "$LOGS_DIR/t03_dio-1es_"$i"_detailed_paths$sufix.txt" ;

        # Run DETAILED_ALL setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_all -e run_number="$i" -e filebench_rate_limit=$FILEBENCH_RATE_LIMITE -e filebench_event_rate=$FILEBENCH_EVENT_GEN_RATE | tee "$LOGS_DIR/t04_dio-1es_"$i"_detailed_all$sufix.txt" ;

        # RUN DETAILED_ALL_UHASH setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_all_uhash -e run_number="$i" -e filebench_rate_limit=$FILEBENCH_RATE_LIMITE -e filebench_event_rate=$FILEBENCH_EVENT_GEN_RATE | tee "$LOGS_DIR/t05_dio-1es_"$i"_detailed_all_uhash$sufix.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        mount_dio_pipeline
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_all_khash -e run_number="$i" -e filebench_rate_limit=$FILEBENCH_RATE_LIMITE -e filebench_event_rate=$FILEBENCH_EVENT_GEN_RATE | tee "$LOGS_DIR/t06_dio-1es_"$i"_detailed_all_khash$sufix.txt" ;

    done
}

function dio_nop {
    # reset kubernetes cluster
    reset_kube_cluster

    mkdir -p $LOGS_DIR

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do

        # Run RAW setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-nop_"$i"_raw.txt" ;

        # Run DETAILED setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-nop_"$i"_detailed.txt" ;

        # # Run DETAILED_PATHS setup
        # ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-nop_"$i"_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-nop_"$i"_detailed_all.txt" ;

        # RUN DETAILED_ALL_UHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_detailed_all_uhash -e run_number="$i" | tee "$LOGS_DIR/t05_dio-nop_"$i"_detailed_all_uhash.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-nop_"$i"_detailed_all_khash.txt" ;

    done
}

# --------

function dio_file_profiling {
    # reset kubernetes cluster
    reset_kube_cluster
    mkdir -p /home/gsd/new_profiling_dio_results/

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do

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

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do

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

function dio_nop_profiling {
    # reset kubernetes cluster
    reset_kube_cluster
    mkdir -p /home/gsd/new_profiling_dio_results/

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do

        mkdir -p $LOGS_DIR

        # Run RAW setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_profiling_raw -e run_number="$i" | tee "$LOGS_DIR/t01_dio-nop_"$i"_profiling_raw.txt" ;

        # Run DETAILED setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_profiling_detailed -e run_number="$i" | tee "$LOGS_DIR/t02_dio-nop_"$i"_profiling_detailed.txt" ;

        # Run DETAILED_PATHS setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_profiling_detailed_paths -e run_number="$i" | tee "$LOGS_DIR/t03_dio-nop_"$i"_profiling_detailed_paths.txt" ;

        # Run DETAILED_ALL setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_profiling_detailed_all -e run_number="$i" | tee "$LOGS_DIR/t04_dio-nop_"$i"_profiling_detailed_all.txt" ;

        # RUN DETAILED_ALL_PLAIN setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_profiling_detailed_all_plain -e run_number="$i" | tee "$LOGS_DIR/t05_dio-nop_"$i"_profiling_detailed_all_plain.txt" ;

        # RUN DETAILED_ALL_KHASH setup
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_nop_profiling_detailed_all_khash -e run_number="$i" | tee "$LOGS_DIR/t06_dio-nop_"$i"_profiling_detailed_all_khash.txt" ;

        # Backup results
        sudo cp -r -n final_test_results/* /home/gsd/new_profiling_dio_results/
        sudo rm -fr final_test_results

    done
}

# --------

function dio_setups_experiments {
    vanilla
    dio_elk
    dio_file
}

function dio_elk_filters {

    setup_kube_cluster

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do
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

        mount_dio_pipeline
        echo "Filebench - DIO - 1 ES, filter rename - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_elk_detailed_filter_renameat2 -e run_number="$i" | tee "$LOGS_DIR/t11_dio-1es_"$i"_detailed_filter_renameat2.txt" ;
    done
}

function dio_file_filters {

    reset_kube_cluster

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do
        mount_dio_pipeline
        echo "Filebench - DIO - FILE, filter tid - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_filter_tid -e run_number="$i" | tee "$LOGS_DIR/t07_dio-file_"$i"_detailed_filter_tid.txt" ;

        mount_dio_pipeline
        echo "Filebench - DIO - FILE, filter orwc - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_filter_orwc -e run_number="$i" | tee "$LOGS_DIR/t08_dio-file_"$i"_detailed_filter_orwc.txt" ;

        mount_dio_pipeline
        echo "Filebench - DIO - FILE, filter read - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_filter_read -e run_number="$i" | tee "$LOGS_DIR/t09_dio-file_"$i"_detailed_filter_read.txt" ;

        mount_dio_pipeline
        echo "Filebench - DIO - FILE, filter stat - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_filter_stat -e run_number="$i" | tee "$LOGS_DIR/t10_dio-file_"$i"_detailed_filter_stat.txt" ;

        mount_dio_pipeline
        echo "Filebench - DIO - FILE, filter rename - Run $i"
        ansible-playbook -u gsd -i hosts.ini filebench_playbook.yml --tags dio_file_detailed_filter_renameat2 -e run_number="$i" | tee "$LOGS_DIR/t11_dio-file_"$i"_detailed_filter_renameat2.txt" ;
    done
}

function dio_filters {
    dio_elk_filters
    dio_file_filters
}

function dio_rate_limit {

    vanilla "true"  12500
    dio_elk "true"  12500

    vanilla "true"  15000
    dio_elk "true"  15000

    vanilla "true"  17500
    dio_elk "true"  17500

    vanilla "true"  20000
    dio_elk "true"  20000

    vanilla "true"  22500
    dio_elk "true"  22500

    vanilla "true"  25000
    dio_elk "true"  25000

    vanilla "true"  50000
    dio_elk "true"  50000

    vanilla "true" 100000
    dio_elk "true" 100000
}

function rocksdb () {
    reset_kube_cluster
    ansible-playbook -u gsd -i hosts.ini rocksdb_dio_playbook.yml --tags load | tee "$LOGS_DIR/rocksdb_load_"$i".txt" ;

    for ((i=$STARTING_RUN; i <= $RUNS; i++)); do
        ansible-playbook -u gsd -i hosts.ini rocksdb_dio_playbook.yml --tags vanilla -e run_number="$i" | tee "$LOGS_DIR/rocksdb_vanilla_"$i".txt" ;

        ansible-playbook -u gsd -i hosts.ini rocksdb_dio_playbook.yml --tags strace -e run_number="$i" | tee "$LOGS_DIR/rocksdb_strace_"$i".txt" ;

        setup_kube_cluster
        ansible-playbook -u gsd -i hosts.ini rocksdb_dio_playbook.yml --tags dio -e run_number="$i" | tee "$LOGS_DIR/rocksdb_dio_"$i".txt" ;
    done

}

function help () {

    echo "Script for running DIO experiments."
    echo
    echo "Usage: ./dio_experiments.sh [OPTION]"
    echo
    echo "Options:"
    echo "  - help, prints this help message"
    echo "  - dio_setups_experiments, runs dio detailed setups experiments (including vanilla, dio_elk and dio_file)"
    echo "  - dio_filters, runs dio filters experiments (including dio_elk_filters and dio_file_filters)"
    echo "  - dio_rate_limit, runs dio rate limit experiments (for rates 12500, 15000, 17500, 20000, 22500, 25000, 50000, 100000)"
}


"$@"