#!/usr/bin/env bash

set -Eeuo pipefail

_msg() {
  echo >&2 -e "${1-}"
}

_msg_print() {
  echo >&2 -n -e "${1-}"
}

_msg_warning() {
  echo >&2 -e "\033[0;33m$1\033[0m"
}

_msg_error() {
  echo >&2 -e "\033[0;31m$1\033[0m"
}

_msg_success() {
  echo >&2 -e "\033[0;32m$1\033[0m"
}

_shout() {
  echo >&2 "$(tput bold)${*}$(tput sgr0)"
}

_die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  _msg_error "😢  $msg"
  exit "$code"
}

report_failure() {
  declare log=$1
  grep Failed "$log"
  grep -E 'Errors.*:.*[A-Z]' -A10 "$log" || true
}

build_solution() {
  _msg "🏗  Building Tanium Sentinel solution"
  pwsh -Command 'Tools/Create-Azure-Sentinel-Solution/createSolution.ps1'
}

build_failed() {
  grep -qm1 '^Failed' "$1"
}

report_success() {
  declare log=$1

  _msg_success "🎉  Build success"

  _msg <<END
  - files: ./Solutions/Tanium/Package/*
  - build log: $log"
END

  _msg "\nYou can now run build_scripts/check.sh to compare this build with the previous build"
}

clear_existing_build_inputs() {
	rm -f ./Tools/Create-Azure-Sentinel-Solution/input/*
}

copy_tanium_build_manifest_into_tooling() {
  cp ./Solutions/Tanium/build_scripts/input.json ./Tools/Create-Azure-Sentinel-Solution/input/Solution_Tanium.json
}

move_tanium_package_directory_to_temporary_location() {
  local tmpdir=$1

  mv "./Solutions/Tanium/Package" "$tmpdir/"
  mkdir -p "./Solutions/Tanium/Package"
}

copy_previous_tanium_package_zip_files_from_temporary_location_back_into_package_directory() {
  local tmpdir=$1
  find "$tmpdir/Package" -name '*.zip' -exec cp "{}" ./Solutions/Tanium/Package \;
}

pre_build_prep() {
  local tmpdir=$1
  _msg "🚮  Clearing existing inputs from the solution build tool"
  clear_existing_build_inputs
  _msg "💾  Copying Tanium build input into the solution build tool"
  copy_tanium_build_manifest_into_tooling
  _msg "🚛  Moving contents of Tanium/Package into a temporary location ($tmpdir) so they are not included in the zip"
  move_tanium_package_directory_to_temporary_location "$tmpdir"
}

post_build_cleanup() {
  local tmpdir=$1
  _msg "🚮  Clearing inputs from the solution build tool"
	rm -f ./Tools/Create-Azure-Sentinel-Solution/input/*
  _msg "🆗  Restoring original inputs in the solution build tool"
	git checkout ./Tools/Create-Azure-Sentinel-Solution/input
  _msg "⏪  Copying zip files from temporary location back into Tanium/Package"
  copy_previous_tanium_package_zip_files_from_temporary_location_back_into_package_directory "$tmpdir"
}

check-command() {
  if ! command -v "$1" >/dev/null; then
    _die "$1 command not found: please brew install ${2-:$1}"
  fi
}

check-new-version() {
  local declared_version
  declared_version=$(jq -r ".Version" Solutions/Tanium/build_scripts/input.json)
  if find Solutions/Tanium/Package -name '*.zip' | grep -q "$declared_version"; then
    _msg
    _msg_error "Found $declared_version.zip already built in Solutions/Tanium/Package"
    _msg
    _msg "Did you forget to increment the version in Solutions/Tanium/build_scripts/input.json?"
    _msg "If you want to rebuild $declared_version then delete the zip file first"
    _msg
    exit 1
  fi
}

check-prerequisites() {
  check-command "jq"
  check-command "git"
  check-command "pwsh" "powershell"
  check-new-version
}


main() {
  (cd "$(git rev-parse --show-toplevel)" || _die "Unable to cd to top level repo directory"
    check-prerequisites
    declare logfile="/tmp/tanium_sentinel_create_package.log"
    declare tmpdir
    tmpdir=$(mktemp -d)
    pre_build_prep "$tmpdir"
    build_solution | tee /dev/tty > "$logfile"
    post_build_cleanup "$tmpdir"
    if build_failed "$logfile"; then
      report_failure "$logfile"
      _die "Detected a build failure"
    fi
    report_success "$logfile"
  )
}

main "$@"
