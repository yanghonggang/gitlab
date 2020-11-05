#!/usr/bin/env bash

function retrieve_tests_metadata() {
  mkdir -p knapsack/ rspec_flaky/ rspec_profiling/

  if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
    wget -O "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "http://${TESTS_METADATA_S3_BUCKET}.s3.amazonaws.com/${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" || echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
  fi

  if [[ ! -f "${FLAKY_RSPEC_SUITE_REPORT_PATH}" ]]; then
    wget -O "${FLAKY_RSPEC_SUITE_REPORT_PATH}" "http://${TESTS_METADATA_S3_BUCKET}.s3.amazonaws.com/${FLAKY_RSPEC_SUITE_REPORT_PATH}" || echo "{}" > "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
  fi
}

function update_tests_metadata() {
  echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"

  scripts/merge-reports "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" knapsack/rspec*.json
  if [[ -n "${TESTS_METADATA_S3_BUCKET}" ]]; then
    if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
      scripts/sync-reports put "${TESTS_METADATA_S3_BUCKET}" "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
    else
      echo "Not uplaoding report to S3 as the pipeline is not a scheduled one."
    fi
  fi

  rm -f knapsack/rspec*.json

  scripts/merge-reports "${FLAKY_RSPEC_SUITE_REPORT_PATH}" rspec_flaky/all_*.json

  export FLAKY_RSPEC_GENERATE_REPORT="true"
  scripts/flaky_examples/prune-old-flaky-examples "${FLAKY_RSPEC_SUITE_REPORT_PATH}"

  if [[ -n ${TESTS_METADATA_S3_BUCKET} ]]; then
    if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
      scripts/sync-reports put "${TESTS_METADATA_S3_BUCKET}" "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
    else
      echo "Not uploading report to S3 as the pipeline is not a scheduled one."
    fi
  fi

  rm -f rspec_flaky/all_*.json rspec_flaky/new_*.json

  if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
    scripts/insert-rspec-profiling-data
  else
    echo "Not inserting profiling data as the pipeline is not a scheduled one."
  fi
}

function retrieve_tests_mapping() {
  mkdir -p crystalball/

  if [[ ! -f "${RSPEC_PACKED_TESTS_MAPPING_PATH}" ]]; then
    (wget -O "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" "http://${TESTS_METADATA_S3_BUCKET}.s3.amazonaws.com/${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" && gzip -d "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz") || echo "{}" > "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
  fi

  scripts/unpack-test-mapping "${RSPEC_PACKED_TESTS_MAPPING_PATH}" "${RSPEC_TESTS_MAPPING_PATH}"
}

function update_tests_mapping() {
  if ! crystalball_rspec_data_exists; then
    echo "No crystalball rspec data found."
    return 0
  fi

  scripts/generate-test-mapping "${RSPEC_TESTS_MAPPING_PATH}" crystalball/rspec*.yml

  scripts/pack-test-mapping "${RSPEC_TESTS_MAPPING_PATH}" "${RSPEC_PACKED_TESTS_MAPPING_PATH}"

  gzip "${RSPEC_PACKED_TESTS_MAPPING_PATH}"

  if [[ -n "${TESTS_METADATA_S3_BUCKET}" ]]; then
    if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
      scripts/sync-reports put "${TESTS_METADATA_S3_BUCKET}" "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz"
    else
      echo "Not uploading report to S3 as the pipeline is not a scheduled one."
    fi
  fi

  rm -f crystalball/rspec*.yml
}

function crystalball_rspec_data_exists() {
  compgen -G "crystalball/rspec*.yml" > /dev/null;
}

function rspec_simple_job() {
  local rspec_opts="${1}"

  export NO_KNAPSACK="1"

  bin/rspec -Ispec -rspec_helper --color --format documentation --format RspecJunitFormatter --out junit_rspec.xml ${rspec_opts}
}

function rspec_paralellized_job() {
  read -ra job_name <<< "${CI_JOB_NAME}"
  local test_tool="${job_name[0]}"
  local test_level="${job_name[1]}"
  local report_name=$(echo "${CI_JOB_NAME}" | sed -E 's|[/ ]|_|g') # e.g. 'rspec unit pg11 1/24' would become 'rspec_unit_pg11_1_24'
  local rspec_opts="${1}"
  local spec_folder_prefix=""

  if [[ "${test_tool}" =~ "-ee" ]]; then
    spec_folder_prefix="ee/"
  fi

  export KNAPSACK_LOG_LEVEL="debug"
  export KNAPSACK_REPORT_PATH="knapsack/${report_name}_report.json"

  # There's a bug where artifacts are sometimes not downloaded. Since specs can run without the Knapsack report, we can
  # handle the missing artifact gracefully here. See https://gitlab.com/gitlab-org/gitlab/-/issues/212349.
  if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
    echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
  fi

  cp "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "${KNAPSACK_REPORT_PATH}"

  if [[ -z "${KNAPSACK_TEST_FILE_PATTERN}" ]]; then
    pattern=$(ruby -r./lib/quality/test_level.rb -e "puts Quality::TestLevel.new(%(${spec_folder_prefix})).pattern(:${test_level})")
    export KNAPSACK_TEST_FILE_PATTERN="${pattern}"
  fi

  echo "KNAPSACK_TEST_FILE_PATTERN: ${KNAPSACK_TEST_FILE_PATTERN}"

  if [[ -d "ee/" ]]; then
    export KNAPSACK_GENERATE_REPORT="true"
    export FLAKY_RSPEC_GENERATE_REPORT="true"
    export SUITE_FLAKY_RSPEC_REPORT_PATH="${FLAKY_RSPEC_SUITE_REPORT_PATH}"
    export FLAKY_RSPEC_REPORT_PATH="rspec_flaky/all_${report_name}_report.json"
    export NEW_FLAKY_RSPEC_REPORT_PATH="rspec_flaky/new_${report_name}_report.json"

    if [[ ! -f $FLAKY_RSPEC_REPORT_PATH ]]; then
      echo "{}" > "${FLAKY_RSPEC_REPORT_PATH}"
    fi

    if [[ ! -f $NEW_FLAKY_RSPEC_REPORT_PATH ]]; then
      echo "{}" > "${NEW_FLAKY_RSPEC_REPORT_PATH}"
    fi
  fi

  mkdir -p tmp/memory_test

  export MEMORY_TEST_PATH="tmp/memory_test/${report_name}_memory.csv"

  knapsack rspec "-Ispec -rspec_helper --color --format documentation --format RspecJunitFormatter --out junit_rspec.xml ${rspec_opts}"

  date
}

function rspec_fail_fast() {
  local test_file_count_threshold=${RSPEC_FAIL_FAST_TEST_FILE_COUNT_THRESHOLD:-10}
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(cat "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally skipped because there are more than ${test_file_count_threshold} test files matched,"
    echo "which would take too long to run in this job."
    echo "All the tests would be run in other rspec jobs."
    exit 0
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job "${rspec_opts} ${test_files}"
  else
    echo "No rspec fail-fast tests to run"
  fi
}

function rspec_matched_foss_tests() {
  local test_file_count_threshold=20
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(cat "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally failed because there are more than ${test_file_count_threshold} FOSS test files matched,"
    echo "which would take too long to run in this job."
    echo "To reduce the likelihood of breaking FOSS pipelines,"
    echo "please add [RUN AS-IF-FOSS] to the MR title and restart the pipeline."
    echo "This would run all as-if-foss jobs in this merge request"
    echo "and remove this failing job from the pipeline."
    exit 1
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job "${rspec_opts} ${test_files}"
  else
    echo "No impacted FOSS rspec tests to run"
  fi
}
