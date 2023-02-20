#! /usr/bin/env bash

AUTOSNAP="com.sun:auto-snapshot"

# Parameters check:
if [[ ${#} < 2 ]] || [[ ${1} == "-h" ]]; then
  echo "zfs-snapshotter usage:"
  echo "  zfs-snapshotter <dataset name> <max snapshots #> [<-r>] [<snapshot suffix>]"
  exit 1
fi

# Dataset name:
DATASET=${1}

# Max number of snapshots to keep:
MAX_SNAPS=${2}

# recurse and Snapshot suffix:
if [[ ${3} == -r ]]; then
  RECURSIV=-r
  SUFFIX="${4}"
else
  SUFFIX="${3}"
fi

# If a suffix is present, normalize it:
if [[ "${SUFFIX}" != "" ]]; then
  SUFFIX=${SUFFIX//./UbErCoOlDoT}
  SUFFIX=${SUFFIX//-/UbErCoOlMiNuS}
  SUFFIX=${SUFFIX//[[:punct:]]/ }
  SUFFIX=$(echo ${SUFFIX//(^ \| $)/} | xargs)
  if [[ ${SUFFIX} != "" ]]; then
    SUFFIX="${SUFFIX// /_}"
    SUFFIX=${SUFFIX//UbErCoOlDoT/.}
    SUFFIX=${SUFFIX//UbErCoOlMiNuS/-}
    SUFFIX="_${SUFFIX}"
  fi
fi

# We dive through all the datasets and just hit those without $AUTOSNAP = false
for DS in `zfs list $DATASET $RECURSIV -H -o name`; do
  if ! [[ `zfs list -H -o $AUTOSNAP $DS` =  "false" ]] \
       || [[ $RECURSIV != -r ]]
  then
    # Snapshot to take:
    SNAP="${DS}@$(date "+%Y-%m-%d_%H-%M")${SUFFIX}"

    # Take in all the DS's snapshots matching the right format:
    SNAPS=(
      $(
        zfs list -t snapshot -o name "${DS}" | \
          grep "@2[0-1][2-9][0-9]-[0-1][0-9]-[0-3][0-9]_[0-2][0-9]-[0-5][0-9]"
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
  fi
done

# Return the outcome of snapshot creation:
exit ${OUTCOME}

