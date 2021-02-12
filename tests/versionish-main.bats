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
  versionish_log="$BATS_TEST_DIRNAME/versionish-main.log"
  pm_maven="$BATS_TEST_DIRNAME/package_managers/maven"
  pm_leiningen="$BATS_TEST_DIRNAME/package_managers/leiningen"
  echo -e "\n\n$BATS_TEST_NAME" 2>&1 >> ${versionish_log}
}

@test "run_main: run versionish functional test on maven" {
  skip "for now unit test all functions on their own"
  run run_main $pm_maven

  assert_success
  assert_output "0.0.1"
}

@test "run_main: run versionish functional test on leiningen" {
  run run_main $pm_leiningen

  assert_success
  assert_output "1.0.0"
}