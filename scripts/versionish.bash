#!/usr/bin/env bash

strict_mode_on() {
  # "unofficial" bash strict mode
  # See: http://redsymbol.net/articles/unofficial-bash-strict-mode
  set -o errexit  # Exit when simple command fails               'set -e'
  set -o errtrace # Exit on error inside any functions or subshells.
  # set -o nounset  # Trigger error when expanding unset variables 'set -u'
  set -o pipefail # Do not hide errors within pipes              'set -o pipefail'
  # set -o xtrace   # Display expanded command and arguments       'set -x'
  IFS=$'\n\t'     # Split words on \n\t rather than spaces
}
strict_mode_on

strict_mode_off() {
  set +o errexit
  set +o errtrace
  set +o nounset
  set +o pipefail
  set +o xtrace
}

# trap 'catch_error $? $LINENO' EXIT

# catch_error() {
#  if [[ "$1" != "0" ]];then
#    echo "Error $1 occurred on line $2"
#    exit $1
#  fi
#}

echoerr() {
  printf "%s\n" "$*" >&2;
}

buildpack_used=
buildpack_output=
versionish_log=/tmp/versionish.log

call_detect() {
  local packs_dir="$1"
  local app_dir="$2"

  if [[ "$packs_dir" == "" || "$app_dir" == "" ]]; then
    echoerr "Parameter packs_dir and app_dir must not be empty."
    exit 2
  fi

  local packs_dir_list=$(find $packs_dir -maxdepth 1 -mindepth 1 -type d -printf '%p, ')
  if [ "$packs_dir_list" == "" ]; then
    exit 10
  fi

  local script_output=
  declare -a dirlist
  mapfile -t dirlist < <(find $packs_dir -maxdepth 1 -mindepth 1 -type d -printf '%p\n')
  echo $packs_dir_list >> ${versionish_log}
  for dir in ${dirlist[@]}; do
    echo "$dir/bin/detect $app_dir" >> ${versionish_log}
    script_output=$($dir/bin/detect $app_dir 2>&1 | tail -n 1)
    local return_code=$?

    echo $script_output >> ${versionish_log}
    if [[ "$return_code" == "0" ]]; then
      local pack_dir=$(basename $dir)
      echo "Version pack '$pack_dir' detected, version information used out of: >$script_output<" >> ${versionish_log}
      echo '{ "pack_dirname" : "'$pack_dir'", "file" : "'$app_dir/$script_output'" }'
      return 0
    fi
  done

  echoerr "No compatible version pack found."
  exit 1
}

call_pack_script() {
  local pack_dir="$1"
  local script_name="$2"
  local script_args="$3"

  if [[ "$pack_dir" == "" || "$script_name" == "" ]]; then
    echoerr "Parameter pack_dir and script_name must not be empty."
    exit 2
  fi

  echo "$pack_dir/bin/$script_name $script_args" >> ${versionish_log}
  if [[ ! -f $pack_dir/bin/$script_name ]]; then
    echoerr "$pack_dir/bin/$script_name does not exist"
    exit 10
  fi
  local script_output
  script_output=$($pack_dir/bin/$script_name $script_args 2>&1 | tail -n 1)
  local return_code=$?
  if [[ "$return_code" == "0" ]]; then
    echo "Script '$script_name' output was: >$script_output<" >> ${versionish_log}

    echo $script_output
    return 0
  fi

  echoerr "'$script_name' returns with error $return_code: $script_output"
  exit 1
}


detect_package_manager() {
  local packs_dir="$1"
  local app_dir="$2"

  echo "Starting package manager detection..." >> ${versionish_log}
  echo "call_detect $packs_dir $app_dir" >> ${versionish_log}
  local script_output=
  script_output=$(call_detect "$packs_dir" "$app_dir")
  local return_code=$?

  echo $script_output
  return $return_code
}

extract_version_number() {
  local pack_dir="$1"
  local file="$2"

  echo "Extracting version number from '$file'..." >> ${versionish_log}
  local version_number=
  version_number=$(call_pack_script "$pack_dir" "extract" "$file")
  local return_code=$?

  echo $version_number
  return $return_code
}

convert_version_number() {
  local pack_dir="$1"
  local raw_version_number="$2"

  echo "Converting version number: $raw_version_number" >> ${versionish_log}
  local semver=
  semver=$(call_pack_script "$pack_dir" "convert" "$raw_version_number")
  local return_code=$?

  echo $semver
  return $return_code
}

#read_config_json() {
#  local config_file="$1"
#  local type="$2"
#
#  local config=$(jq -c '.tools[] | select(.buildpack=="'$type'")' $config_file)
#  echo $config
#}

# main entrypoint of this script
run_main() {
  echo "$log_prefix versionish called..." >> ${versionish_log}
  local app_dir="$1"
  local versionish_dir="/tmp/versionish"
  local packs_dir="$versionish_dir/packs"
  local log_prefix="-->"

  # switch to app_dir for user convenience
  echo "$log_prefix Change directory to: $app_dir" >> ${versionish_log}
  cd $app_dir

  local result_json=$(detect_package_manager $packs_dir $app_dir)
  echo "$log_prefix Using version pack: $result_json" >> ${versionish_log}
  local pack_dirname=$(echo $result_json | jq -r '.pack_dirname')
  echo "$log_prefix Proceeding with version pack: $pack_dirname" >> ${versionish_log}
  local file=$(echo $result_json | jq -r '.file')
  echo "$log_prefix Trying to extract version number from file: $file" >> ${versionish_log}

  # local config=$(read_config_json $versionish_dir/config.json "Java")
  # echo $config >> ${versionish_log}

  # local input_type=$(echo $config | jq -r '.input.type')
  # local input_command=$(echo $config | jq -r '.input.command')

  local pack_dir="$packs_dir/$pack_dirname"
  local raw_version_number=$(extract_version_number $pack_dir $file)
  echo "$log_prefix got raw version number: $raw_version_number" >> ${versionish_log}
  local semver=$(convert_version_number $pack_dir $raw_version_number)
  echo "$log_prefix converted to semantic version number: $semver" >> ${versionish_log}

  echo $semver
  return 0
}

# do not automgically execute main method when sourced for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  run_main
  if [ $? -gt 0 ]
  then
    exit 1
  fi
fi

