#!/usr/bin/env bash


# Colors and symbols
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
INVERT='\033[7m'
NC='\033[0m'
CHECK_MARK="✓"
CROSS_MARK="✗"
WARN_MARK="!"
RIGHT_ARROW="→ "

# Test result counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNED_TESTS=0
NOTED_TESTS=0

# Terminal output - use colors
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    INVERT='\033[7m'
    NC='\033[0m'
	CHECK_MARK="✓"
	CROSS_MARK="✗"
	WARN_MARK="!"
	NOTE_MARK="ℹ"
	RIGHT_ARROW="→ "
else
    # Non-terminal output (file/pipe) - no colors
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    INVERT=''
    NC=''
	CHECK_MARK="SUCCESS"
	CROSS_MARK="FAIL"
	WARN_MARK="WARN"
	NOTE_MARK="NOTE"
	RIGHT_ARROW=""
fi

# Check if Linux
if [[ $(uname -s) != "Linux" ]]; then
    echo
    printf "${BOLD}${RED}%s This script must be run on a Linux system${NC}\n" "${CROSS_MARK}"
	echo
    exit 1
fi


# Enhanced result storage
declare -A SYSTEM_INFO
declare -A SYSTEM_SETTINGS
declare -A SYSTEM_NETWORK
declare -a CHECK_RESULTS

collect_check_result() {
    local name=$1
    local status=$2
    local actual_value=$3
    local expected_value=$4
    local description=$5
    local docs_url=${6:-}

    CHECK_RESULTS+=("${name}|${status}|${actual_value}|${expected_value}|${description}|${docs_url}")
    ((TOTAL_TESTS++))
    case $status in
        "PASS") ((PASSED_TESTS++));;
        "WARN") ((WARNED_TESTS++));;
        "FAIL") ((FAILED_TESTS++));;
        "NOTE") ((NOTED_TESTS++));;
    esac
}

print_system_report() {
    echo
    printf '%b%b System Information %b\n' "${BOLD}" "${INVERT}" "${NC}"
    printf "%s\n" "----------------------------------------"
    for key in "${!SYSTEM_INFO[@]}"; do
        printf "${BOLD}%-20s${NC} %s\n" "$key:" "${SYSTEM_INFO[$key]}"
    done
	echo
	for key in "${!SYSTEM_NETWORK[@]}"; do
        printf "${BOLD}%-20s${NC} %s\n" "$key:" "${SYSTEM_NETWORK[$key]}"
    done
	echo
	for key in "${!SYSTEM_SETTINGS[@]}"; do
        printf "${BOLD}%-20s${NC} %s\n" "$key:" "${SYSTEM_SETTINGS[$key]}"
    done
}

print_detailed_summary() {
    print_system_report
    echo
    printf '%b%b Report Results %b\n' "${BOLD}" "${INVERT}" "${NC}"
    printf "%s\n" "----------------------------------------"
    
    for result in "${CHECK_RESULTS[@]}"; do
        IFS='|' read -r name status actual expected desc url <<< "$result"
        case $status in
            "PASS")
                printf "${GREEN}%s ${name}${NC}\n" "${CHECK_MARK}"
                printf "   Current: ${GREEN}%s${NC}\n" "$actual"
                ;;
            "WARN")
                printf "${YELLOW}%s ${name}${NC}\n" "${WARN_MARK}"
                printf "   Current: ${YELLOW}%s${NC}\n" "$actual"
                printf "   Expected: %s\n" "$expected"
                printf "   Note: %s\n" "$desc"
                ;;
            "FAIL")
                printf "${RED}%s ${name}${NC}\n" "${CROSS_MARK}"
                printf "   Current: ${RED}%s${NC}\n" "$actual"
                printf "   Expected: %s\n" "$expected"
                printf "   Error: %s\n" "$desc"
                ;;
            "NOTE")
                printf '%b%s%b %s%b\n' "${BLUE}" "${NOTE_MARK}" "${NC}" "${name}" "${NC}"
                printf "   %s\n" "$desc"
                ;;
        esac
        if [[ -n "$url" ]]; then
            printf "   ${BLUE}${RIGHT_ARROW}Documentation: %s${NC}\n" "$url"
        fi
        echo
    done

    # Print summary counts
    printf "%s\n" "----------------------------------------"
    printf "Total Checks: %d\n" "$TOTAL_TESTS"
    printf "${GREEN}%s Passed: %d${NC}\n" "${CHECK_MARK}" "$PASSED_TESTS"
    printf "${RED}%s Failed: %d${NC}\n" "${CROSS_MARK}" "$FAILED_TESTS"
    printf "${YELLOW}%s Warnings: %d${NC}\n" "${WARN_MARK}" "$WARNED_TESTS"
    printf "${BLUE}${NOTE_MARK} Notes: %d${NC}\n" "$NOTED_TESTS"
	echo
}

# Early exit if any checks fail
critical_failure_exit() {
	print_detailed_summary
	echo
	printf '%b%b%b%s Critical checks failed. Exiting early.%b\n' "${RED}" "${BOLD}" "${INVERT}" "${CROSS_MARK}" "${NC}"
	echo
	exit 1
}

# Run all checks
run_preflight_checks() {
    echo
    printf '%b%b Running QPoint Preflight Checks %b\n' "${BOLD}" "${INVERT}" "${NC}"
    echo

    # Collect basic system information
    SYSTEM_INFO["OS"]=$(uname -s)
	SYSTEM_INFO["Architecture"]=$(uname -m)
    SYSTEM_INFO["Kernel Version"]=$(uname -r)

    # Run all checks
    check_root
    check_kernel
    check_lockdown
    check_cgroups_v2
    collect_sysctl_bpf
	check_network_interfaces
}

# Check if script is running with root privileges
check_root() {
    if [[ $EUID -eq 0 ]]; then
        collect_check_result \
            "Root Privileges" \
            "PASS" \
            "root" \
            "root" \
            "Script is running with root privileges"
    else
        collect_check_result \
            "Root Privileges" \
            "FAIL" \
            "non-root" \
            "root" \
            "This script must be run with root privileges. Please run with: sudo $0" \
            "https://docs.example.com/root-requirements"
        exit 1
    fi
}

# Check if kernel version is ≥ 5.10
check_kernel() {
    local kernel_version
    kernel_version=$(uname -r | cut -d. -f1-2)
    
    if awk -v ver="$kernel_version" 'BEGIN{exit(!(ver >= 5.10))}'; then
        collect_check_result \
            "Kernel Version" \
            "PASS" \
            "$kernel_version" \
            "≥ 5.10" \
            "Kernel version is sufficient"
    else
        collect_check_result \
            "Kernel Version" \
            "FAIL" \
            "$kernel_version" \
            "≥ 5.10" \
            "Kernel version 5.10 or higher is required"
    fi
}

# Check /sys/kernel/security/lockdown for none (pass) or integrity (warn) or confidential (fail)
check_lockdown() {
    local lockdown_file="/sys/kernel/security/lockdown"
    local current_mode

    if [[ ! -f "$lockdown_file" ]]; then
        current_mode="not available"
        collect_check_result \
            "Kernel Lockdown" \
            "FAIL" \
            "$current_mode" \
            "none" \
            "Kernel lockdown file not found" \
            "https://docs.qpoint.io/qtap/troubleshooting/linux-kernel-lockdown-for-ebpf-applications"
		SYSTEM_SETTINGS["Kernel Lockdown"]=$current_mode
        return
    fi

    current_mode=$(cat "$lockdown_file")
    SYSTEM_SETTINGS["Kernel Lockdown"]=$current_mode

    case $current_mode in
        "none")
            collect_check_result \
                "Kernel Lockdown" \
                "PASS" \
                "$current_mode" \
                "none" \
                "Optimal setting for full functionality"
            ;;
        "integrity")
            collect_check_result \
                "Kernel Lockdown" \
                "WARN" \
                "$current_mode" \
                "none" \
                "Some QPoint functionality may be restricted" \
                "https://docs.qpoint.io/qtap/troubleshooting/linux-kernel-lockdown-for-ebpf-applications"
            ;;
        *)
            collect_check_result \
                "Kernel Lockdown" \
                "FAIL" \
                "$current_mode" \
                "none" \
                "Unsupported lockdown mode" \
                "https://docs.qpoint.io/qtap/troubleshooting/linux-kernel-lockdown-for-ebpf-applications"
            ;;
    esac
}

# Check if cgroups v2 is enabled
check_cgroups_v2() {
    local cgroup_info
    cgroup_info=$(mount | grep "cgroup2" || echo "not mounted")
    SYSTEM_SETTINGS["Cgroups"]=$cgroup_info

    if mount | grep -q "cgroup2"; then
        collect_check_result \
            "Cgroups v2" \
            "PASS" \
            "enabled" \
            "enabled" \
            "Cgroups v2 is properly configured"
    else
        collect_check_result \
            "Cgroups v2" \
            "FAIL" \
            "disabled" \
            "enabled" \
            "Cgroups v2 is required for QPoint"
    fi
}

# Check sysctl bpf settings
collect_sysctl_bpf() {
    local sysctl_settings=(
        "kernel.bpf_stats_enabled|0"
        "kernel.unprivileged_bpf_disabled|1"
        "net.core.bpf_jit_enable|1"
        "net.core.bpf_jit_harden|2"
        "net.core.bpf_jit_kallsyms|1"
        "net.core.bpf_jit_limit|-1"
    )

    # Build a formatted string of all BPF settings
    local bpf_info=""
    for setting in "${sysctl_settings[@]}"; do
        IFS='|' read -r param expected description <<< "$setting"
        current=$(sysctl -n "$param" 2>/dev/null || echo "not found")
        if [[ "$expected" == "-1" ]]; then
            bpf_info+=" - $param\t= $current\n"
        else
            bpf_info+=" - $param\t= $current\t(recommended: $expected)\n"
        fi
    done

	SYSTEM_SETTINGS["BPF Settings"]=$(echo -e "\n$bpf_info" | sed 's/\\n/; /g' | sed 's/; $//')
}

# Check network interfaces
check_network_interfaces() {
    local ipv4_interfaces=""
    local ipv6_interfaces=""
    
    # Try multiple methods to get network interfaces
	if command -v ip >/dev/null 2>&1; then
		# Use ip command if available
		ipv4_interfaces=$(ip -4 addr show | grep inet | grep -v '127.0.0.1' | awk '{print $NF ":" $2}')
		ipv6_interfaces=$(ip -6 addr show | grep inet6 | grep -v fe80 | grep -v '::1' | awk '{print $NF ":" $2}')
	elif command -v ifconfig >/dev/null 2>&1; then
		# Fallback to ifconfig
		ipv4_interfaces=$(/sbin/ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $NF ":" $2}')
		ipv6_interfaces=$(/sbin/ifconfig | grep 'inet6' | grep -v 'fe80' | grep -v '::1' | awk '{print $NF ":" $6}')
	fi
    
    SYSTEM_NETWORK["IPv4 Interfaces"]="${ipv4_interfaces:-None Detected}"
    SYSTEM_NETWORK["IPv6 Interfaces"]="${ipv6_interfaces:-None Detected}"

    if [[ -z "$ipv4_interfaces" && -z "$ipv6_interfaces" ]]; then
        collect_check_result \
            "Network Interfaces" \
            "FAIL" \
            "No valid interfaces" \
            "At least one interface" \
            "No network interfaces with global unicast addresses found"
        return
    fi

    # Check IPv4 interfaces
    if [[ -n "$ipv4_interfaces" ]]; then
        collect_check_result \
            "IPv4 Interfaces" \
            "PASS" \
            "$ipv4_interfaces" \
            "At least one interface" \
            "Valid IPv4 interfaces found"
    else
        collect_check_result \
            "IPv4 Interfaces" \
            "WARN" \
            "None" \
            "At least one interface" \
            "No IPv4 interfaces found"
    fi

    # Check IPv6 interfaces
    if [[ -n "$ipv6_interfaces" ]]; then
        collect_check_result \
            "IPv6 Interfaces" \
            "PASS" \
            "$ipv6_interfaces" \
            "At least one interface" \
            "Valid IPv6 interfaces found"
    else
        collect_check_result \
            "IPv6 Interfaces" \
            "WARN" \
            "None" \
            "At least one interface" \
            "No IPv6 interfaces found"
    fi
}

# Main execution
run_preflight_checks
print_detailed_summary