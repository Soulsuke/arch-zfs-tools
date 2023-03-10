#! /usr/bin/env bash

# Iterate over all pools:
for pool in $(zpool list -o name -H); do
  # Just in case:
  echo -n "Checking pool '${pool}'..."

  # Control variables:
  NUMBER=0
  TOTAL=0
  MIN=9999999999999
  MIN_NAMES=()
  MAX=0
  MAX_NAMES=()

  # This is needed to split the following list only on newlines:
  IFS=$'\n'
  for u in $(zfs list -pH -t snapshot -o name,used -r "${pool}"); do
    # Then we have to unset it to split the single line on spaces/tabs:
    unset IFS
    SPLIT=( ${u} )

    # Increase the number of snapshots and the total used space:
    NUMBER=$(( NUMBER + 1 ))
    TOTAL=$(( TOTAL + SPLIT[ 1 ] ))

    # Check for smallest snapshots:
    if [[ ${MIN} -ge ${SPLIT[ 1 ]} ]]; then
      # New low, save it and clean previous stored names:
      if [[ ${MIN} != ${SPLIT[ 1 ]} ]]; then
        MIN=${SPLIT[ 1 ]}
        MIN_NAMES=()
      fi

      # Save the snao's name:
      MIN_NAMES+=( "${SPLIT[ 0 ]}" )
    fi

     # Check for biggest snapshots:
    if [[ ${MAX} -le ${SPLIT[ 1 ]} ]]; then
      # New high, save it and clean previous stored names:
      if [[ ${MAX} != ${SPLIT[ 1 ]} ]]; then
        MAX=${SPLIT[ 1 ]}
        MAX_NAMES=()
      fi

      # Save the snao's name:
      MAX_NAMES+=( "${SPLIT[ 0 ]}" )
    fi
  done

  # Current pool's report:
  echo -e "\033[2K\rPool: ${pool}"
  echo "  Snapshots: ${NUMBER}"

  # Only show these if we actually have any snapshots:
  if [[ ${NUMBER} -ge 1 ]]; then
    echo "  Used space: $(numfmt --to=iec <<< ${TOTAL})"
    echo "  Smallest snapshot(s) ($(numfmt --to=iec <<< ${MIN})):"
    for n in ${MIN_NAMES[@]}; do
      echo "    ${n}"
    done
    echo "  Biggest snapshot(s) ($(numfmt --to=iec <<< ${MAX})):"
    for n in ${MAX_NAMES[@]}; do
      echo "    ${n}"
    done
  fi
done

