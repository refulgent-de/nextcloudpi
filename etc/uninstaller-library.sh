#!/usr/bin/env bash

# Uninstall-Skript Generator 0.1.0
#
# Author: javanaut@refulgent.de

APT_VERSION_MATCH="[^[:blank:]]+[[:blank:]]+([^[:blank:]]+)"


if [[ $USG_STATUS != "OK" ]]; then

  if [[ -z $(apt -qq --installed list apt 2>/dev/null) ]]; then
    echo "Error: apt not present or syntax for listing of installed packages was changed -> exiting" >&2
    exit 1
  fi

  apt-get update

  USG_UNINSTALL_SCRIPT="$USG_SCRIPT_DIR/uninstall-nextcloudpi-$(date '+%Y-%m-%d-%H-%M-%S').sh"

  echo "#!/usr/bin/env bash" > $USG_UNINSTALL_SCRIPT
  chmod 750 $USG_UNINSTALL_SCRIPT
  echo -en "\n" >> $USG_UNINSTALL_SCRIPT
  echo "Creating uninstaller in $USG_UNINSTALL_SCRIPT"

  declare -A USG_INSTALLED_PACKAGES

  USG_STATUS="OK"
fi

usg_getInstalledVersion() {

  if [[ ${USG_INSTALLED_PACKAGES[$1]+_} ]]; then
    echo "${USG_INSTALLED_PACKAGES[$1]}"
    return
  fi

  if [[ $(dpkg -s $1 2>/dev/null | grep "Version:") =~ $APT_VERSION_MATCH ]]; then
      USG_INSTALLED_PACKAGES[$1]=${BASH_REMATCH[1]}
      echo "${USG_INSTALLED_PACKAGES[$1]}"
  fi
}

usg_install() {

  unset APT_OPTIONS
  local OPTIND o
  while getopts "t:" o; do 
    case "${o}" in
      t)
        APT_OPTIONS="-t ${OPTARG}"
        echo $APT_OPTIONS
        ;;
    esac
  done
  shift "$((OPTIND-1))"

  for package; do # for iterates per default on $@

    # usage of return in subfunction messes up for loop
    version="$(usg_getInstalledVersion $package)"

    if [[ -z "$version" ]]; then
      echo "apt-get install -y --no-install-recommends $APT_OPTIONS $package"
      echo "apt-get purge $package" >> $USG_UNINSTALL_SCRIPT
    fi
      
    USG_INSTALLED_PACKAGES[$package]="$(usg_getInstalledVersion $package)"
  done
}

usg_mkdir() {
  [[ ! -d "$1" ]] &&
    echo "rm -rf $1" >> $USG_UNINSTALL_SCRIPT
  mkdir -p "$1"
}

usg_finalize() {
  echo -en "\n" >> $USG_UNINSTALL_SCRIPT
  echo "apt-get autoremove --purge" >> $USG_UNINSTALL_SCRIPT
}