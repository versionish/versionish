#!/usr/bin/env bats

load test_helper

setup_file() {
  versionish_log="$BATS_TEST_DIRNAME/versionish.log"
  rm -f $versionish_log
}

setup() {
  versionish_dir="/tmp/versionish"
  packs_dir="$versionish_dir/packs"
  pack_under_test="$packs_dir/05_pack-maven"
  versionish="${versionish_dir}/versionish.bash"
  source ${versionish}
  pm_maven="$BATS_TEST_DIRNAME/package_managers/maven"
  echo -e "\n\n$BATS_TEST_NAME" 2>&1 >> ${versionish_log}

  # change to working copy
  cd $pm_maven
}

@test "call_detect: no version pack found" {
  run call_detect /not/exist $pm_maven

  assert_failure 10
  assert_output --partial "/not/exist"
  assert_output --partial "No such file or directory"
}

@test "call_detect: app_dir does not exist" {
  run call_detect $packs_dir /not/exist

  assert_failure 2
  assert_output "app_dir does not exist or is inaccessible"
}

@test "call_detect: a maven version pack found" {
  run call_detect $packs_dir $pm_maven

  assert_success
  assert_output '{ "pack_dirname" : "05_pack-maven", "file" : "/tests/./package_managers/maven/pom.xml" }'
}

@test "call_detect: no app_dir given" {
  run call_detect $packs_dir

  assert_failure 2
  assert_output "Parameter packs_dir and app_dir must not be empty."
}

@test "call_detect: no packs_dir nor app_dir given" {
  run call_detect

  assert_failure 2
  assert_output "Parameter packs_dir and app_dir must not be empty."
}

@test "call_pack_script: script_name and script_args parameter not set" {
  run call_pack_script $pack_under_test

  assert_failure 2
  assert_output "Parameter pack_dir and script_name must not be empty."
}

@test "call_pack_script: no parameters given" {
  run call_pack_script

  assert_failure 2
  assert_output "Parameter pack_dir and script_name must not be empty."
}

@test "call_pack_script: pack_dir does not exist" {
  run call_pack_script "/not/exist" "extract"

  assert_failure 10
  assert_output "/not/exist/bin/extract does not exist"
}

@test "call_pack_script: script_name set to unknown script" {
  run call_pack_script $pack_under_test "unknown"

  assert_failure 10
  assert_output "$pack_under_test/bin/unknown does not exist"
}

@test "call_pack_script: script_args not set" {
  run call_pack_script $pack_under_test "extract"

  assert_failure 1
  assert_output "'extract' returns with error 1: version file name was not be given"
}

@test "call_pack_script: extract snapshot version from pom.xml successfully" {
  skip "too long"
  run call_pack_script $pack_under_test "extract" "$pm_maven/pom.xml"

  assert_success
  assert_output "0.0.1-SNAPSHOT"
}

@test "detect_package_manager: packs_dir not set" {
  run detect_package_manager

  assert_failure 2
  assert_output "Parameter packs_dir and app_dir must not be empty."
}

@test "detect_package_manager: app_dir not set" {
  run detect_package_manager $packs_dir

  assert_failure 2
  assert_output "Parameter packs_dir and app_dir must not be empty."
}

@test "detect_package_manager: packs_dir set to unknown directory" {
  run detect_package_manager "/not/exist" $pm_maven

  assert_failure 10
  assert_output "find: ‘/not/exist’: No such file or directory"
}

@test "detect_package_manager: app_dir set to unknown directory" {
  run detect_package_manager "$packs_dir" "/not/exist"

  assert_failure 2
  assert_output "app_dir does not exist or is inaccessible"
}

@test "detect_package_manager: detect a java application using maven pom.xml" {
  run detect_package_manager "$packs_dir" "$pm_maven"

  assert_success
  assert_output --partial "pom.xml"
  assert_output --partial "05_pack-maven"
}

@test "extract_version_number: pack_dir not set" {
  run extract_version_number

  assert_failure 2
  assert_output "Parameter pack_dir and script_name must not be empty."
}

@test "extract_version_number: file not set" {
  run extract_version_number "$pack_under_test"

  assert_failure 1
  assert_output "'extract' returns with error 1: version file name was not be given"
}

@test "extract_version_number: successful extraction" {
  skip "too long"
  run extract_version_number "$pack_under_test" "$pm_maven/pom.xml"

  assert_success
  assert_output "0.0.1-SNAPSHOT"
}

@test "convert_version_number: pack_dir not set" {
  run convert_version_number

  assert_failure 2
  assert_output "Parameter pack_dir and script_name must not be empty."
}

@test "convert_version_number: version_number not given" {
  run convert_version_number "$pack_under_test"

  assert_failure 1
  assert_output "'convert' returns with error 1: version number missing"
}

@test "convert_version_number: convert version number 1.0.0-SNAPSHOT" {
  run convert_version_number "$pack_under_test" "1.0.0-SNAPSHOT"

  assert_success
  assert_output "1.0.0"
}

@test "convert_version_number: conversion failed caused by wrong version number" {
  run convert_version_number "$pack_under_test" "01.2020"

  assert_failure 1
  assert_output "'convert' returns with error 2: '01.2020' is not a valid semantic version, aborting"
}

#@test "read_config_json: read configuration for Java buildpack" {
#  run read_config_json "${versionish_dir}/config.json" "Java"
#
#  assert_success
#  assert_output --partial "{\"buildpack\":\"Java\",\"input\":{"
#}
