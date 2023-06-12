#! /usr/bin/env bash

# Root check:
if [[ ! 0 == ${UID} ]]; then
  echo "You need root privileges to run this."
  exit 1
fi

# Dependencies check (better safe than sorry):
for D in curl efibootmgr grep mount sed umount; do
  if [[ ! $(command -v ${D}) ]]; then
    echo "Command not found: ${D}"
    unset D
    exit 1
  fi
done

# Utility cleanup function, takes as parameter the exit value:
function cleanup()
{
  umount "${EFI}" &> /dev/null
  rmdir	 "${EFI}" &> /dev/null
  rm "${TMP_DWN}" &> /dev/null
  unset D EFI EBM EFI_DEVICE ZBM_PATH DATA LATEST URL INSTALLED TMP_DWN
  exit $1
}

# Get zfsbootmenu's entry:
EBM=$(efibootmgr --verbose | grep -i zfsbootmenu.EFI | sed -E 's,\\,\\\\,g')
if [[ "" == ${EBM} ]]; then
  echo "No existing ZBM entry found via efibootmgr."
  cleanup 2
fi

# Temporary EFI mountpoint:
EFI="/root/efi_$(date "+%Y%m%d%H%M%S")"
mkdir -p "${EFI}"

# Find the EFI device via partuuid:
EFI_DEVICE="/dev/disk/by-partuuid/$(sed -E 's/(.*GPT,|,.*)//g' <<< ${EBM})"

# Get ZBM's path inside the EFI partition:
ZBM_PATH="${EFI}/$(
  sed -E 's,(\\zfsbootmenu\.EFI\).*|.*\(\\\\),,g' <<< ${EBM} |
    sed -E 's,\\,/,g'
)/zfsbootmenu.EFI"

# Temporary ZBM download path:
TMP_DWN="/tmp/zfsbootmenu.EFI"

# Mount EFI partition:
umount "${EFI_DEVICE}" &> /dev/null
mount \
  -o rw \
  -o relatime \
  -o fmask=0177 \
  -o dmask=0077 \
  -o iocharset=utf8 \
  -o shortname=mixed \
  "${EFI_DEVICE}" "${EFI}" &> /dev/null
if [[ ! 0 == $? ]]; then
  echo "Failed to mount ${EFI_DEVICE}."
  cleanup 3
fi

# Ensure this path exists in case EFI partition is empty but efibootmngr
# reports an entry:
mkdir -p "$(dirname ${ZBM_PATH})"
if [[ ! 0 == $? ]]; then
  echo "Failed to create ZBM folder in EFI partition."
  cleanup 4
fi

# Fetch info about the latest release from git:
DATA=$(
  curl --silent \
    "https://api.github.com/repos/zbm-dev/zfsbootmenu/releases/latest"
)
if [[ ! 0 == $? ]]; then
  echo "Failed to fetch data from git."
  cleanup 5
fi

# Parse latest release data:
LATEST=$(grep '"tag_name":' <<< ${DATA} | sed -E 's/.*"([^"]+)".*/\1/')
URL=$(
  grep browser_download_url <<< ${DATA} |
    grep -e ".*release-.*EFI.*" | 
    sed -E 's/(^.* "|".*$)//g'
)

# Installed version (if info is available):
INSTALLED=$(cat "${ZBM_PATH}.version" 2> /dev/null)

# Print out some info:
echo "Latest version: ${LATEST}"
echo "Installed version: ${INSTALLED}"

# Update ZBM if necessary:
if [[ ! ${INSTALLED} == ${LATEST} ]]; then
  echo -e "\nDownloading latest version via curl:"

  # Download ZBM in a temporary folder:
  rm "${TMP_DWN}" &> /dev/null
  curl -L "${URL}" -o "${TMP_DWN}"
  if [[ ! 0 == $? ]]; then
    echo "Failed to download latest ZBM."
    cleanup 6
  fi

  # Backup the previous version if needed:
  if [[ -e "${ZBM_PATH}" ]]; then
    mv -f "${ZBM_PATH}" "${ZBM_PATH}.old"
    echo "${INSTALLED}" > "${ZBM_PATH}.old.version"
  fi

  # Move in the new version:
  mv "${TMP_DWN}" "${ZBM_PATH}"
  echo "${LATEST}" > "${ZBM_PATH}.version"
fi

# Final touches:
cleanup 0

