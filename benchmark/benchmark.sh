#!/bin/bash
# =============================================================================
# benchmark.sh
# Research Paper: A Comparative Study of Infrastructure Automation Tools
# Purpose: Measures and logs deployment time for Ansible, Terraform, Puppet
# Authors: Risham Goyal, Vaibhav Khanna, Sujal Jain — Chitkara University
#
# Usage:
#   chmod +x benchmark.sh
#   ./benchmark.sh --tool ansible --nodes 10 --runs 5
#   ./benchmark.sh --tool all    --nodes 10 --runs 5
# =============================================================================

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
TOOL="all"
NODES=10
RUNS=5
LOG_DIR="./logs"
RESULTS_FILE="./benchmark_results.csv"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colour

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)    TOOL="$2";  shift 2 ;;
    --nodes)   NODES="$2"; shift 2 ;;
    --runs)    RUNS="$2";  shift 2 ;;
    --help)
      echo "Usage: $0 [--tool ansible|terraform|puppet|all] [--nodes N] [--runs N]"
      exit 0
      ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Setup ─────────────────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR"

echo "Tool,Nodes,Run,Duration_seconds,CPU_percent,RAM_mb,Status" > "$RESULTS_FILE"

print_header() {
  echo -e "\n${CYAN}=================================================================${NC}"
  echo -e "${CYAN}  Cloud Automation Tools Benchmark — Research Study${NC}"
  echo -e "${CYAN}  Chitkara University, Dept. of CSE${NC}"
  echo -e "${CYAN}=================================================================${NC}"
  echo -e "  Tool    : ${YELLOW}${TOOL}${NC}"
  echo -e "  Nodes   : ${YELLOW}${NODES}${NC}"
  echo -e "  Runs    : ${YELLOW}${RUNS}${NC}"
  echo -e "  Timestamp: ${TIMESTAMP}"
  echo -e "${CYAN}=================================================================${NC}\n"
}

# ── Resource monitoring (background) ─────────────────────────────────────────
start_monitoring() {
  local tool=$1
  local run=$2
  local monitor_file="${LOG_DIR}/${tool}_run${run}_monitor.log"

  # Sample CPU and RAM every 2 seconds during run
  (
    while true; do
      cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
      ram=$(free -m | awk '/^Mem:/{print $3}')
      echo "$(date +%s),${cpu},${ram}" >> "$monitor_file"
      sleep 2
    done
  ) &
  echo $!  # Return PID of monitor process
}

stop_monitoring() {
  local pid=$1
  kill "$pid" 2>/dev/null || true
}

get_avg_resources() {
  local monitor_file=$1
  if [[ ! -f "$monitor_file" ]]; then
    echo "0,0"
    return
  fi
  awk -F',' '{cpu+=$2; ram+=$3; count++} END {printf "%.1f,%.0f", cpu/count, ram/count}' "$monitor_file"
}

# ── Tool runners ──────────────────────────────────────────────────────────────
run_ansible() {
  local run_num=$1
  local log_file="${LOG_DIR}/ansible_run${run_num}_${TIMESTAMP}.log"

  echo -e "  ${BLUE}[Ansible]${NC} Run ${run_num}/${RUNS} — ${NODES} nodes..."

  monitor_pid=$(start_monitoring "ansible" "$run_num")
  start_time=$(date +%s%N)

  cd ../ansible
  ansible-playbook playbook.yml \
    -i inventory/aws_ec2.yml \
    -e "node_count=${NODES}" \
    --forks=10 \
    > "$log_file" 2>&1
  exit_code=$?
  cd - > /dev/null

  end_time=$(date +%s%N)
  stop_monitoring "$monitor_pid"

  duration=$(( (end_time - start_time) / 1000000000 ))
  resources=$(get_avg_resources "${LOG_DIR}/ansible_run${run_num}_monitor.log")
  cpu=$(echo "$resources" | cut -d',' -f1)
  ram=$(echo "$resources" | cut -d',' -f2)
  status=$([[ $exit_code -eq 0 ]] && echo "SUCCESS" || echo "FAILED")

  echo "ansible,${NODES},${run_num},${duration},${cpu},${ram},${status}" >> "$RESULTS_FILE"
  echo -e "     Duration: ${GREEN}${duration}s${NC} | CPU: ${cpu}% | RAM: ${ram}MB | ${status}"
}

run_terraform() {
  local run_num=$1
  local log_file="${LOG_DIR}/terraform_run${run_num}_${TIMESTAMP}.log"

  echo -e "  ${BLUE}[Terraform]${NC} Run ${run_num}/${RUNS} — ${NODES} nodes..."

  monitor_pid=$(start_monitoring "terraform" "$run_num")
  start_time=$(date +%s%N)

  cd ../terraform
  terraform apply \
    -var="node_count=${NODES}" \
    -auto-approve \
    > "$log_file" 2>&1
  exit_code=$?
  # Destroy after each run to start fresh
  terraform destroy -var="node_count=${NODES}" -auto-approve >> "$log_file" 2>&1
  cd - > /dev/null

  end_time=$(date +%s%N)
  stop_monitoring "$monitor_pid"

  duration=$(( (end_time - start_time) / 1000000000 ))
  resources=$(get_avg_resources "${LOG_DIR}/terraform_run${run_num}_monitor.log")
  cpu=$(echo "$resources" | cut -d',' -f1)
  ram=$(echo "$resources" | cut -d',' -f2)
  status=$([[ $exit_code -eq 0 ]] && echo "SUCCESS" || echo "FAILED")

  echo "terraform,${NODES},${run_num},${duration},${cpu},${ram},${status}" >> "$RESULTS_FILE"
  echo -e "     Duration: ${GREEN}${duration}s${NC} | CPU: ${cpu}% | RAM: ${ram}MB | ${status}"
}

run_puppet() {
  local run_num=$1
  local log_file="${LOG_DIR}/puppet_run${run_num}_${TIMESTAMP}.log"

  echo -e "  ${BLUE}[Puppet]${NC} Run ${run_num}/${RUNS} — ${NODES} nodes..."

  monitor_pid=$(start_monitoring "puppet" "$run_num")
  start_time=$(date +%s%N)

  # Trigger puppet agent run on all nodes via SSH
  # (In experiment, nodes run agent --test on command from master)
  parallel-ssh -h /etc/puppet/nodes.txt \
    "sudo puppet agent --test --onetime --no-daemonize" \
    > "$log_file" 2>&1
  exit_code=$?

  end_time=$(date +%s%N)
  stop_monitoring "$monitor_pid"

  duration=$(( (end_time - start_time) / 1000000000 ))
  resources=$(get_avg_resources "${LOG_DIR}/puppet_run${run_num}_monitor.log")
  cpu=$(echo "$resources" | cut -d',' -f1)
  ram=$(echo "$resources" | cut -d',' -f2)
  status=$([[ $exit_code -eq 0 ]] && echo "SUCCESS" || echo "FAILED")

  echo "puppet,${NODES},${run_num},${duration},${cpu},${ram},${status}" >> "$RESULTS_FILE"
  echo -e "     Duration: ${GREEN}${duration}s${NC} | CPU: ${cpu}% | RAM: ${ram}MB | ${status}"
}

# ── Summary report ────────────────────────────────────────────────────────────
print_summary() {
  echo -e "\n${CYAN}=================================================================${NC}"
  echo -e "${CYAN}  BENCHMARK RESULTS SUMMARY${NC}"
  echo -e "${CYAN}=================================================================${NC}"
  echo -e "  Results saved to: ${YELLOW}${RESULTS_FILE}${NC}"
  echo ""

  # Calculate averages per tool using awk
  awk -F',' '
    NR==1 { next }
    $7=="SUCCESS" {
      tool=$1; dur[$1]+=$4; cpu[$1]+=$5; ram[$1]+=$6; count[$1]++
    }
    END {
      printf "  %-12s %-15s %-12s %-12s\n", "Tool", "Avg Duration", "Avg CPU%", "Avg RAM(MB)"
      printf "  %-12s %-15s %-12s %-12s\n", "----", "------------", "--------", "-----------"
      for (t in dur) {
        printf "  %-12s %-15.1fs %-12.1f %-12.0f\n",
          t, dur[t]/count[t], cpu[t]/count[t], ram[t]/count[t]
      }
    }
  ' "$RESULTS_FILE"

  echo -e "${CYAN}=================================================================${NC}\n"
}

# ── Main ──────────────────────────────────────────────────────────────────────
print_header

case $TOOL in
  ansible)
    echo -e "${YELLOW}Running Ansible benchmark...${NC}"
    for i in $(seq 1 $RUNS); do run_ansible $i; done
    ;;
  terraform)
    echo -e "${YELLOW}Running Terraform benchmark...${NC}"
    for i in $(seq 1 $RUNS); do run_terraform $i; done
    ;;
  puppet)
    echo -e "${YELLOW}Running Puppet benchmark...${NC}"
    for i in $(seq 1 $RUNS); do run_puppet $i; done
    ;;
  all)
    echo -e "${YELLOW}Running all tools benchmark...${NC}\n"
    for i in $(seq 1 $RUNS); do run_ansible $i;    done
    for i in $(seq 1 $RUNS); do run_terraform $i;  done
    for i in $(seq 1 $RUNS); do run_puppet $i;     done
    ;;
  *)
    echo -e "${RED}Unknown tool: $TOOL. Use ansible, terraform, puppet, or all.${NC}"
    exit 1
    ;;
esac

print_summary
echo -e "${GREEN}Benchmark complete!${NC}"
