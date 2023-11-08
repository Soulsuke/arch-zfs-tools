#! /usr/bin/env bash



# Root check:
if [[ ${UID} != 0 ]]; then
  echo "You need root privileges to run this script."
  exit 1
fi



# These are taken by parameters:
KERNEL="${1}" # linux
UCODE="${2}" # intel-ucode
SUFFIX="${3}" # bundled-ucode



# Parameters check:
if [[ -z "${KERNEL}" ]] || [[ -z "${UCODE}" ]] || [[ -z "${SUFFIX}" ]]; then
  echo "Missing positional parameters - kernel: _${KERNEL}_ -" \
    "ucode: _${UCODE}_ - suffix: _${SUFFIX}_"
  exit 2
fi



# Variables, needed later on:
KERNEL_MD5_PATH="/boot/.initramfs-${KERNEL}.md5"
UCODE_MD5_PATH="/boot/.${UCODE}.md5"
KERNEL_PATH="/boot/initramfs-${KERNEL}.img"
UCODE_PATH="/boot/${UCODE}.img"
KERNEL_MD5=""
UCODE_MD5=""
KERNEL_MD5_NEW=""
UCODE_MD5_NEW=""



# If kernel or ucode hasn't been found, simply quit:
if [[ ! -f "${KERNEL_PATH}" ]] || [[ ! -f "${UCODE_PATH}" ]]; then
  echo "Kernel or ucode not found: ${KERNEL_PATH} - ${UCODE_PATH}"
  exit 3
fi

# Get the current MD5 sums:
KERNEL_MD5_NEW="$(md5sum "${KERNEL_PATH}" | awk '{ print $1 }')"
UCODE_MD5_NEW="$(md5sum "${UCODE_PATH}" | awk '{ print $1 }')"

# Get the previously stored MD5 sums:
[[ -f "${KERNEL_MD5_PATH}" ]] && KERNEL_MD5="$(cat "${KERNEL_MD5_PATH}")"
[[ -f "${UCODE_MD5_PATH}" ]] && UCODE_MD5="$(cat "${UCODE_MD5_PATH}")"

# Otherwise, if checksums are different:
if [[ "${KERNEL_MD5}" != "${KERNEL_MD5_NEW}" ]] || \
   [[ "${UCODE_MD5}" != "${UCODE_MD5_NEW}" ]]
then
  # Generate a new image:
  cat "${UCODE_PATH}" "${KERNEL_PATH}" > \
    "/boot/initramfs-${KERNEL}-${SUFFIX}.img"
  ln -Tsrf "/boot/vmlinuz-${KERNEL}" "/boot/vmlinuz-${KERNEL}-${SUFFIX}"

  # Update md5sums:
  echo "${KERNEL_MD5_NEW}" > "${KERNEL_MD5_PATH}"
  echo "${UCODE_MD5_NEW}" > "${UCODE_MD5_PATH}"

  # Just for the record:
  echo "Created a new image."
fi

