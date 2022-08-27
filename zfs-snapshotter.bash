#! /usr/bin/env bash

# Parameters check:
if [[ ${#} < 2 ]] || [[ ${1} == -h ]]; then
  echo "zfs-snapshotter usage:"
  echo "  zfs-snapshotter <dataset name> <max snapshots #> <snapshot suffix>"
  exit 1
fi

# Dataset name:
DATASET=${1}

# Max number of snapshots to keep:
MAX_SNAPS=${2}

# Snapshot suffix:
SUFFIX="${3}"

# If a suffix is present, normalize it:
if [[ "${SUFFIX}" != "" ]]; then
  SUFFIX=${SUFFIX//./UbErCoOlDoT}
  SUFFIX=${SUFFIX//-/UbErCoOlMiNuS}
  SUFFIX=${SUFFIX//[[:punct:]]/ }
  SUFFIX=$(echo ${SUFFIX//(^ \| $)/} | xargs )
  if [[ ${SUFFIX} != "" ]]; then
    SUFFIX="${SUFFIX// /_}"
    SUFFIX=${SUFFIX//UbErCoOlDoT/.}
    SUFFIX=${SUFFIX//UbErCoOlMiNuS/-}
    SUFFIX="_${SUFFIX}"
  fi
fi

# Snapshot to take:
SNAP="${DATASET}@$(date "+%Y-%m-%d")${SUFFIX}"

# Take in all the dataset's snapshots matching the right format:
SNAPS=(
  $(
    zfs list -t snapshot -o name -r "${DATASET}" | \
      grep '@2[0-1][2-9][0-9]-[0-1][0-9]-[0-3][0-9]'
  )
)

# If a snapshot with the name we need is already taken, do nothing:
if [[ " ${SNAPS[*]} " =~ " ${SNAP} " ]]; then
  echo "Snapshot '${SNAP}' already exists, skipping."
  exit 2
fi

# If we got here, take the new snapshot:
zfs snapshot "${SNAP}"
OUTCOME=${?}

# If the snapshot was successful and we already reached the threshold, remove
# the exceeding ones:
if [[ 0 == ${OUTCOME} ]] && [[ ${#SNAPS} -ge ${MAX_SNAPS} ]]; then
  for(( i=0; i<=$((${#SNAPS[@]} - ${MAX_SNAPS})) && i<${#SNAPS[@]}; i++ )); do
    zfs destroy "${SNAPS[${i}]}"
  done
fi

# Return the outcome of snapshot creation:
exit ${OUTCOME}

