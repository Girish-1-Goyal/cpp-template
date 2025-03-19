#!/bin/bash

# Dark Colors using tput
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)

# Bold and reset
bold=$(tput bold)
reset=$(tput sgr0)

# Settings
CPP_VERSION="c++17"
COMPILE_FLAGS="-Wall -Wextra -O2"
TEST_GEN_FILE="./stress_tester/test_gen.cpp"
MAIN_FILE="sol.cpp"
INPUT_FILE="in"
MAX_TESTS=5
TIME_LIMIT=2  # seconds per test case

usage() {
    echo -e "${bold}${cyan}Usage:${reset} $(basename "$0") [-t <num_tests>]"
    exit 1
}

while getopts "t:h" opt; do
    case $opt in
        t)
            MAX_TESTS="$OPTARG"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

log_info() {
    echo -e "${bold}${blue}[INFO]${reset} $1"
}
log_success() {
    echo -e "${bold}${green}[SUCCESS]${reset} $1"
}
log_error() {
    echo -e "${bold}${red}[ERROR]${reset} $1"
}
log_warning() {
    echo -e "${bold}${yellow}[WARNING]${reset} $1"
}

check_files() {
    echo ""
    echo "---------------------------------------------------------"
    local missing=0
    if [ ! -f "$MAIN_FILE" ]; then
        log_error "Main solution file ${yellow}$MAIN_FILE${reset} not found!"
        missing=1
    fi
    if [ ! -f "$TEST_GEN_FILE" ]; then
        log_error "Test case generator file ${yellow}$TEST_GEN_FILE${reset} not found!"
        missing=1
    fi
    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

compile_file() {
    local src_file="$1"
    local exe_file="$2"
    local extra_flags="$3"
    log_info "Compiling ${yellow}$src_file${reset}..."
    local start_ns=$(date +%s%N)
    # Capture compiler errors
    compile_output=$(g++ -std="$CPP_VERSION" $COMPILE_FLAGS $extra_flags "$src_file" -o "$exe_file" 2>&1)
    if [ $? -ne 0 ]; then
        log_error "Compilation failed for ${yellow}$src_file${reset}."
        echo -e "${red}Compiler output:${reset}"
        echo "$compile_output"
        exit 1
    fi
    local end_ns=$(date +%s%N)
    local compile_time_ns=$((end_ns - start_ns))
    local compile_time_ms=$(echo "scale=3; $compile_time_ns/1000000" | bc)
    log_success "Compiled ${yellow}$src_file${reset} to ${magenta}$exe_file${reset} in ${cyan}${compile_time_ms} ms${reset}."
}

stress_test() {
    local accepted=0
    local failed=0
    local total_test_time_ns=0
    echo -e "\n${bold}${red}Starting stress testing with ${yellow}$MAX_TESTS${red} test cases...${reset}"
    for (( i=1; i<=MAX_TESTS; i++ )); do
        echo -e "\n${bold}${blue}======= Test case #$i =======${reset}"
        
        ./generator > "$INPUT_FILE"
        echo -e "${bold}${magenta}[Input]:${reset}"
        cat "$INPUT_FILE"
        echo ""
        
        local start_ns=$(date +%s%N)
        # Run solution with timeout to catch TLE; capture both output and errors
        output=$(timeout $TIME_LIMIT ./sol < "$INPUT_FILE" 2>&1)
        local ret_code=$?
        local end_ns=$(date +%s%N)
        local elapsed_ns=$((end_ns - start_ns))
        total_test_time_ns=$((total_test_time_ns + elapsed_ns))
        local elapsed_ms=$(echo "scale=3; $elapsed_ns/1000000" | bc)
        
        echo -e "${bold}${cyan}[Output]:${reset}"
        echo -e "$output"
        
        if [ $ret_code -eq 0 ]; then
            echo -e "${bold}${green}Test case #$i: Accepted in ${blue}${elapsed_ms} ms${reset}"
            ((accepted++))
        elif [ $ret_code -eq 124 ]; then
            echo -e "${bold}${red}Test case #$i: Time Limit Exceeded (TLE) after ${yellow}${elapsed_ms} ms${reset}"
            ((failed++))
        elif [ $ret_code -eq 137 ]; then
            echo -e "${bold}${red}Test case #$i: Memory Limit Exceeded (MLE) in ${yellow}${elapsed_ms} ms${reset}"
            ((failed++))
        elif [ $ret_code -eq 139 ]; then
            echo -e "${bold}${red}Test case #$i: Runtime Error (Segmentation Fault) in ${yellow}${elapsed_ms} ms${reset}"
            ((failed++))
        else
            echo -e "${bold}${red}Test case #$i: Runtime Error (exit code $ret_code) in ${yellow}${elapsed_ms} ms${reset}"
            ((failed++))
        fi
        echo -e "${bold}${white}=====================================${reset}"
    done

    total_test_time_ms=$(echo "scale=3; $total_test_time_ns/1000000" | bc)
    avg_time=$(echo "scale=3; $total_test_time_ms/$MAX_TESTS" | bc)
    
    echo -e "\n${bold}${red}Stress testing completed.${reset}"
    echo -e "${bold}${green}[Accepted]: $accepted${reset}    ${bold}${red}[Failed]: $failed${reset}"
    echo -e "${bold}${cyan}[Total testing time]: ${total_test_time_ms} ms${reset}"
    echo -e "${bold}${magenta}[Average time per test]: ${avg_time} ms${reset}"
    echo ""
}

# -----------------------#
#  Main Execution       #
# -----------------------#
check_files

compile_file "$TEST_GEN_FILE" "generator" ""
compile_file "$MAIN_FILE" "sol" ""

stress_test
