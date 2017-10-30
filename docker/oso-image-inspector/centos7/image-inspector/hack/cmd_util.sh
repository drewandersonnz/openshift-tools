#!/bin/bash

# see https://github.com/openshift/origin/blob/master/hack/cmd_util.sh

# This utility file contains functions that wrap commands to be tested. All wrapper functions run commands
# in a sub-shell and redirect all output. Tests in test-cmd *must* use these functions for testing.

# We assume ${II_ROOT} is set
source "${II_ROOT}/hack/text.sh"
source "${II_ROOT}/hack/util.sh"

# expect_success runs the cmd and expects an exit code of 0
function ii::cmd::expect_success() {
	if [[ $# -ne 1 ]]; then echo "ii::cmd::expect_success expects only one argument, got $#"; exit 1; fi
	local cmd=$1

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}"
}

# expect_failure runs the cmd and expects a non-zero exit code
function ii::cmd::expect_failure() {
	if [[ $# -ne 1 ]]; then echo "ii::cmd::expect_failure expects only one argument, got $#"; exit 1; fi
	local cmd=$1

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}" "ii::cmd::internal::failure_func"
}

# expect_success_and_text runs the cmd and expects an exit code of 0
# as well as running a grep test to find the given string in the output
function ii::cmd::expect_success_and_text() {
	if [[ $# -ne 2 ]]; then echo "ii::cmd::expect_success_and_text expects two arguments, got $#"; exit 1; fi
	local cmd=$1
	local expected_text=$2

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}" "ii::cmd::internal::success_func" "${expected_text}"
}

# expect_failure_and_text runs the cmd and expects a non-zero exit code
# as well as running a grep test to find the given string in the output
function ii::cmd::expect_failure_and_text() {
	if [[ $# -ne 2 ]]; then echo "ii::cmd::expect_failure_and_text expects two arguments, got $#"; exit 1; fi
	local cmd=$1
	local expected_text=$2

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}" "ii::cmd::internal::failure_func" "${expected_text}"
}

# expect_success_and_not_text runs the cmd and expects an exit code of 0
# as well as running a grep test to ensure the given string is not in the output
function ii::cmd::expect_success_and_not_text() {
	if [[ $# -ne 2 ]]; then echo "ii::cmd::expect_success_and_not_text expects two arguments, got $#"; exit 1; fi
	local cmd=$1
	local expected_text=$2

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}" "ii::cmd::internal::success_func" "${expected_text}" "ii::cmd::internal::failure_func"
}

# expect_failure_and_not_text runs the cmd and expects a non-zero exit code
# as well as running a grep test to ensure the given string is not in the output
function ii::cmd::expect_failure_and_not_text() {
	if [[ $# -ne 2 ]]; then echo "ii::cmd::expect_failure_and_not_text expects two arguments, got $#"; exit 1; fi
	local cmd=$1
	local expected_text=$2

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}" "ii::cmd::internal::failure_func" "${expected_text}" "ii::cmd::internal::failure_func"
}

# expect_code runs the cmd and expects a given exit code
function ii::cmd::expect_code() {
	if [[ $# -ne 2 ]]; then echo "ii::cmd::expect_code expects two arguments, got $#"; exit 1; fi
	local cmd=$1
	local expected_cmd_code=$2

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}" "ii::cmd::internal::specific_code_func ${expected_cmd_code}"
}

# expect_code_and_text runs the cmd and expects the given exit code
# as well as running a grep test to find the given string in the output
function ii::cmd::expect_code_and_text() {
	if [[ $# -ne 3 ]]; then echo "ii::cmd::expect_code_and_text expects three arguments, got $#"; exit 1; fi
	local cmd=$1
	local expected_cmd_code=$2
	local expected_text=$3

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}" "ii::cmd::internal::specific_code_func ${expected_cmd_code}" "${expected_text}"
}

# expect_code_and_not_text runs the cmd and expects the given exit code
# as well as running a grep test to ensure the given string is not in the output
function ii::cmd::expect_code_and_not_text() {
	if [[ $# -ne 3 ]]; then echo "ii::cmd::expect_code_and_not_text expects three arguments, got $#"; exit 1; fi
	local cmd=$1
	local expected_cmd_code=$2
	local expected_text=$3

	ii::cmd::internal::expect_exit_code_run_grep "${cmd}" "ii::cmd::internal::specific_code_func ${expected_cmd_code}" "${expected_text}" "ii::cmd::internal::failure_func"
}

millisecond=1
second=$(( 1000 * millisecond ))
minute=$(( 60 * second ))

# ii::cmd::try_until_success runs the cmd in a small interval until either the command succeeds or times out
# the default time-out for ii::cmd::try_until_success is 60 seconds.
# the default interval for ii::cmd::try_until_success is 200ms
function ii::cmd::try_until_success() {
	if [[ $# -lt 1 ]]; then echo "ii::cmd::try_until_success expects at least one arguments, got $#"; exit 1; fi
	local cmd=$1
	local duration=${2:-minute}
	local interval=${3:-0.2}

	ii::cmd::internal::run_until_exit_code "${cmd}" "ii::cmd::internal::success_func" "${duration}" "${interval}"
}

# ii::cmd::try_until_failure runs the cmd until either the command fails or times out
# the default time-out for ii::cmd::try_until_failure is 60 seconds.
function ii::cmd::try_until_failure() {
	if [[ $# -lt 1 ]]; then echo "ii::cmd::try_until_success expects at least one argument, got $#"; exit 1; fi
	local cmd=$1
	local duration=${2:-$minute}
	local interval=${3:-0.2}

	ii::cmd::internal::run_until_exit_code "${cmd}" "ii::cmd::internal::failure_func" "${duration}" "${interval}"
}

# ii::cmd::try_until_text runs the cmd until either the command outputs the desired text or times out
# the default time-out for ii::cmd::try_until_text is 60 seconds.
function ii::cmd::try_until_text() {
	if [[ $# -lt 2 ]]; then echo "ii::cmd::try_until_success expects at least two arguments, got $#"; exit 1; fi
	local cmd=$1
	local text=$2
	local duration=${3:-minute}
	local interval=${4:-0.2}

	ii::cmd::internal::run_until_text "${cmd}" "${text}" "${duration}" "${interval}"
}

# Functions in the ii::cmd::internal namespace are discouraged from being used outside of ii::cmd

# In order to harvest stderr and stdout at the same time into different buckets, we need to stick them into files
# in an intermediate step
BASETMPDIR="${TMPDIR:-"/tmp"}/openshift"
os_cmd_internal_tmpdir="${BASETMPDIR}/test-cmd"
os_cmd_internal_tmpout="${os_cmd_internal_tmpdir}/tmp_stdout.log"
os_cmd_internal_tmperr="${os_cmd_internal_tmpdir}/tmp_stderr.log"

# ii::cmd::internal::expect_exit_code_run_grep runs the provided test command and expects a specific
# exit code from that command as well as the success of a specified `grep` invocation. Output from the
# command to be tested is suppressed unless either `VERBOSE=1` or the test fails. This function bypasses
# any error exiting settings or traps set by upstream callers by masking the return code of the command
# with the return code of setting the result variable on failure.
#
# Globals:
#  - VERBOSE
# Arguments:
#  - 1: the command to run
#  - 2: command evaluation assertion to use
#  - 3: text to test for
#  - 4: text assertion to use
# Returns:
#  - 0: if all assertions met
#  - 1: if any assertions fail
function ii::cmd::internal::expect_exit_code_run_grep() {
	local cmd=$1
	# default expected cmd code to 0 for success
	local cmd_eval_func=${2:-ii::cmd::internal::success_func}
	# default to nothing
	local grep_args=${3:-}
	# default expected test code to 0 for success
	local test_eval_func=${4:-ii::cmd::internal::success_func}

	ii::cmd::internal::init_tempdir

	local name=$(ii::cmd::internal::describe_call "${cmd}" "${cmd_eval_func}" "${grep_args}" "${test_eval_func}")
	echo "Running ${name}..."

	local start_time=$(ii::cmd::internal::seconds_since_epoch)

	local cmd_result=$( ii::cmd::internal::run_collecting_output "${cmd}"; echo $? )
	local cmd_succeeded=$( ${cmd_eval_func} "${cmd_result}"; echo $? )

	local test_result=0
	if [[ -n "${grep_args}" ]]; then
		test_result=$( ii::cmd::internal::run_collecting_output 'ii::cmd::internal::get_results | grep -Eq "${grep_args}"'; echo $? )

	fi
	local test_succeeded=$( ${test_eval_func} "${test_result}"; echo $? )

	local end_time=$(ii::cmd::internal::seconds_since_epoch)
	local time_elapsed=$(echo "scale=3; ${end_time} - ${start_time}" | bc | xargs printf '%5.3f') # in decimal seconds, we need leading zeroes for parsing later

	# some commands are multi-line, so we may need to clear more than just the previous line
	local cmd_length=$(echo "${cmd}" | wc -l)
	for (( i=0; i<${cmd_length}; i++ )); do
		ii::text::clear_last_line
	done

	local return_code
	if (( cmd_succeeded && test_succeeded )); then
		ii::text::print_green "SUCCESS after ${time_elapsed}s: ${name}"
		if [[ -n ${VERBOSE-} ]]; then
			ii::cmd::internal::print_results
		fi
		return_code=0
	else
		local cause=$(ii::cmd::internal::assemble_causes "${cmd_succeeded}" "${test_succeeded}")

		ii::text::print_red_bold "FAILURE after ${time_elapsed}s: ${name}: ${cause}"
		ii::text::print_red "$(ii::cmd::internal::print_results)"
		return_code=1
	fi

	# append inside of a subshell so that IFS doesn't get propagated out
	return "${return_code}"

}

# ii::cmd::internal::init_tempdir initializes the temporary directory
function ii::cmd::internal::init_tempdir() {
	mkdir -p "${os_cmd_internal_tmpdir}"
	rm -f "${os_cmd_internal_tmpdir}"/tmp_std{out,err}.log
}

# ii::cmd::internal::describe_call determines the file:line of the latest function call made
# from outside of this file in the call stack, and the name of the function being called from
# that line, returning a string describing the call
function ii::cmd::internal::describe_call() {
	local cmd=$1
	local cmd_eval_func=$2
	local grep_args=${3:-}
	local test_eval_func=${4:-}

	local caller_id=$(ii::cmd::internal::determine_caller)
	local full_name="${caller_id}: executing '${cmd}'"

	local cmd_expectation=$(ii::cmd::internal::describe_expectation "${cmd_eval_func}")
	local full_name="${full_name} expecting ${cmd_expectation}"

	if [[ -n "${grep_args}" ]]; then
		local text_expecting=
		case "${test_eval_func}" in
		"ii::cmd::internal::success_func")
			text_expecting="text" ;;
		"ii::cmd::internal::failure_func")
			text_expecting="not text" ;;
		esac
		full_name="${full_name} and ${text_expecting} '${grep_args}'"
	fi

	echo "${full_name}"
}

# ii::cmd::internal::determine_caller determines the file relative to the OpenShift Origin root directory
# and line number of the function call to the outer ii::cmd wrapper function
function ii::cmd::internal::determine_caller() {
	local call_depth=
	local len_sources="${#BASH_SOURCE[@]}"
	for (( i=0; i<${len_sources}; i++ )); do
		if [ ! $(echo "${BASH_SOURCE[i]}" | grep "hack/cmd_util\.sh$") ]; then
			call_depth=i
			break
		fi
	done

	local caller_file="${BASH_SOURCE[${call_depth}]}"
	if which realpath >&/dev/null; then
		# if the caller has `realpath`, we can use it to make our file names cleaner by
		# trimming the absolute file path up to `...openshift/origin/` and showing only
		# the relative path from the Origin root directory
		caller_file="$( realpath "${caller_file}" )"
		caller_file="${caller_file//*openshift\/origin\/}"
	fi
	local caller_line="${BASH_LINENO[${call_depth}-1]}"
	echo "${caller_file}:${caller_line}"
}

# ii::cmd::internal::describe_expectation describes a command return code evaluation function
function ii::cmd::internal::describe_expectation() {
	local func=$1
	case "${func}" in
	"ii::cmd::internal::success_func")
		echo "success" ;;
	"ii::cmd::internal::failure_func")
		echo "failure" ;;
	"ii::cmd::internal::specific_code_func"*[0-9])
		local code=$(echo "${func}" | grep -Eo "[0-9]+$")
		echo "exit code ${code}" ;;
	"")
		echo "any result"
	esac
}

# ii::cmd::internal::seconds_since_epoch returns the number of seconds elapsed since the epoch
# with milli-second precision
function ii::cmd::internal::seconds_since_epoch() {
	local ns=$(date +%s%N)
	# if `date` doesn't support nanoseconds, return second precision
	if [[ "$ns" == *N ]]; then
		date "+%s.000"
		return
	fi
	echo $(bc <<< "scale=3; ${ns}/1000000000")
}

# ii::cmd::internal::run_collecting_output runs the command given, piping stdout and stderr into
# the given files, and returning the exit code of the command
function ii::cmd::internal::run_collecting_output() {
	local cmd=$1

	local result=
	$( eval "${cmd}" 1>>"${os_cmd_internal_tmpout}" 2>>"${os_cmd_internal_tmperr}" ) || result=$?
	local result=${result:-0} # if we haven't set result yet, the command succeeded

	return "${result}"
}

# ii::cmd::internal::success_func determines if the input exit code denotes success
# this function returns 0 for false and 1 for true to be compatible with arithmetic tests
function ii::cmd::internal::success_func() {
	local exit_code=$1

	# use a negated test to get output correct for (( ))
	[[ "${exit_code}" -ne "0" ]]
	return $?
}

# ii::cmd::internal::failure_func determines if the input exit code denotes failure
# this function returns 0 for false and 1 for true to be compatible with arithmetic tests
function ii::cmd::internal::failure_func() {
	local exit_code=$1

	# use a negated test to get output correct for (( ))
	[[ "${exit_code}" -eq "0" ]]
	return $?
}

# ii::cmd::internal::specific_code_func determines if the input exit code matches the given code
# this function returns 0 for false and 1 for true to be compatible with arithmetic tests
function ii::cmd::internal::specific_code_func() {
	local expected_code=$1
	local exit_code=$2

	# use a negated test to get output correct for (( ))
	[[ "${exit_code}" -ne "${expected_code}" ]]
	return $?
}

# ii::cmd::internal::get_results prints the stderr and stdout files
function ii::cmd::internal::get_results() {
	cat "${os_cmd_internal_tmpout}" "${os_cmd_internal_tmperr}"
}

# ii::cmd::internal::get_try_until_results returns a concise view of the stdout and stderr output files
# using a timeline format, where consecutive output lines that are the same are condensed into one line
# with a counter
function ii::cmd::internal::print_try_until_results() {
	if grep -vq $'\x1e' "${os_cmd_internal_tmpout}"; then
		echo "Standard output from the command:"
		ii::cmd::internal::compress_output "${os_cmd_internal_tmpout}"
	else
		echo "There was no output from the command."
	fi

	if grep -vq $'\x1e' "${os_cmd_internal_tmperr}"; then
		echo "Standard error from the command:"
		ii::cmd::internal::compress_output "${os_cmd_internal_tmperr}"
	else
		echo "There was no error output from the command."
	fi
}

# ii::cmd::internal::mark_attempt marks the end of an attempt in the stdout and stderr log files
# this is used to make the try_until_* output more concise
function ii::cmd::internal::mark_attempt() {
	echo -e '\x1e' >> "${os_cmd_internal_tmpout}" | tee "${os_cmd_internal_tmperr}"
}

# ii::cmd::internal::compress_output compresses an output file into timeline representation
function ii::cmd::internal::compress_output() {
	local logfile=$1

	awk -f ${II_ROOT}/hack/compress.awk $logfile
}

# ii::cmd::internal::print_results pretty-prints the stderr and stdout files
function ii::cmd::internal::print_results() {
	if [[ -s "${os_cmd_internal_tmpout}" ]]; then
		echo "Standard output from the command:"
		cat "${os_cmd_internal_tmpout}"; echo
	else
		echo "There was no output from the command."
	fi

	if [[ -s "${os_cmd_internal_tmperr}" ]]; then
		echo "Standard error from the command:"
		cat "${os_cmd_internal_tmperr}"; echo
	else
		echo "There was no error output from the command."
	fi
}

# ii::cmd::internal::assemble_causes determines from the two input booleans which part of the test
# failed and generates a nice delimited list of failure causes
function ii::cmd::internal::assemble_causes() {
	local cmd_succeeded=$1
	local test_succeeded=$2

	local causes=()
	if (( ! cmd_succeeded )); then
		causes+=("the command returned the wrong error code")
	fi
	if (( ! test_succeeded )); then
		causes+=("the output content test failed")
	fi

	local list=$(printf '; %s' "${causes[@]}")
	echo "${list:2}"
}


# ii::cmd::internal::run_until_exit_code runs the provided command until the exit code test given
# succeeds or the timeout given runs out. Output from the command to be tested is suppressed unless
# either `VERBOSE=1` or the test fails. This function bypasses any error exiting settings or traps
# set by upstream callers by masking the return code of the command with the return code of setting
# the result variable on failure.
#
# Globals:
#  - VERBOSE
# Arguments:
#  - 1: the command to run
#  - 2: command evaluation assertion to use
#  - 3: timeout duration
#  - 4: interval duration
# Returns:
#  - 0: if all assertions met before timeout
#  - 1: if timeout occurs
function ii::cmd::internal::run_until_exit_code() {
	local cmd=$1
	local cmd_eval_func=$2
	local duration=$3
	local interval=$4

	ii::cmd::internal::init_tempdir

	local description=$(ii::cmd::internal::describe_call "${cmd}" "${cmd_eval_func}")
	local duration_seconds=$(echo "scale=3; $(( duration )) / 1000" | bc | xargs printf '%5.3f')
	local description="${description}; re-trying every ${interval}s until completion or ${duration_seconds}s"
	echo "Running ${description}..."

	local start_time=$(ii::cmd::internal::seconds_since_epoch)

	local deadline=$(( $(date +%s000) + $duration ))
	local cmd_succeeded=0
	while [ $(date +%s000) -lt $deadline ]; do
		local cmd_result=$( ii::cmd::internal::run_collecting_output "${cmd}"; echo $? )
		cmd_succeeded=$( ${cmd_eval_func} "${cmd_result}"; echo $? )
		if (( cmd_succeeded )); then
			break
		fi
		sleep "${interval}"
		ii::cmd::internal::mark_attempt
	done

	local end_time=$(ii::cmd::internal::seconds_since_epoch)
	local time_elapsed=$(echo "scale=9; ${end_time} - ${start_time}" | bc | xargs printf '%5.3f') # in decimal seconds, we need leading zeroes for parsing later

	# some commands are multi-line, so we may need to clear more than just the previous line
	local cmd_length=$(echo "${cmd}" | wc -l)
	for (( i=0; i<${cmd_length}; i++ )); do
		ii::text::clear_last_line
	done

	local return_code
	if (( cmd_succeeded )); then
		ii::text::print_green "SUCCESS after ${time_elapsed}s: ${description}"

		if [[ -n ${VERBOSE-} ]]; then
			ii::cmd::internal::print_try_until_results
		fi
		return_code=0
	else
		ii::text::print_red_bold "FAILURE after ${time_elapsed}s: ${description}: the command timed out"

		ii::text::print_red "$(ii::cmd::internal::print_try_until_results)"
		return_code=1
	fi

	return "${return_code}"
}

# ii::cmd::internal::run_until_text runs the provided command until the command output contains the
# given text or the timeout given runs out. Output from the command to be tested is suppressed unless
# either `VERBOSE=1` or the test fails. This function bypasses any error exiting settings or traps
# set by upstream callers by masking the return code of the command with the return code of setting
# the result variable on failure.
#
# Globals:
#  - VERBOSE
# Arguments:
#  - 1: the command to run
#  - 2: text to test for
#  - 3: timeout duration
#  - 4: interval duration
# Returns:
#  - 0: if all assertions met before timeout
#  - 1: if timeout occurs
function ii::cmd::internal::run_until_text() {
	local cmd=$1
	local text=$2
	local duration=$3
	local interval=$4

	ii::cmd::internal::init_tempdir

	local description=$(ii::cmd::internal::describe_call "${cmd}" "" "${text}" "ii::cmd::internal::success_func")
	local duration_seconds=$(echo "scale=3; $(( duration )) / 1000" | bc | xargs printf '%5.3f')
	local description="${description}; re-trying every ${interval}s until completion or ${duration_seconds}s"
	echo "Running ${description}..."

	local start_time=$(ii::cmd::internal::seconds_since_epoch)

	local deadline=$(( $(date +%s000) + $duration ))
	local test_succeeded=0
	while [ $(date +%s000) -lt $deadline ]; do
		local cmd_result=$( ii::cmd::internal::run_collecting_output "${cmd}"; echo $? )
		local test_result=$( ii::cmd::internal::run_collecting_output 'ii::cmd::internal::get_results | grep -Eq "${text}"'; echo $? )
		test_succeeded=$( ii::cmd::internal::success_func "${test_result}"; echo $? )

		if (( test_succeeded )); then
			break
		fi
		sleep "${interval}"
		ii::cmd::internal::mark_attempt
	done

	local end_time=$(ii::cmd::internal::seconds_since_epoch)
	local time_elapsed=$(echo "scale=9; ${end_time} - ${start_time}" | bc | xargs printf '%5.3f') # in decimal seconds, we need leading zeroes for parsing later

	# some commands are multi-line, so we may need to clear more than just the previous line
	local cmd_length=$(echo "${cmd}" | wc -l)
	for (( i=0; i<${cmd_length}; i++ )); do
		ii::text::clear_last_line
	done

	local return_code
	if (( test_succeeded )); then
		ii::text::print_green "SUCCESS after ${time_elapsed}s: ${description}"

		if [[ -n ${VERBOSE-} ]]; then
			ii::cmd::internal::print_try_until_results
		fi
		return_code=0
	else
		ii::text::print_red_bold "FAILURE after ${time_elapsed}s: ${description}: the command timed out"

		ii::text::print_red "$(ii::cmd::internal::print_try_until_results)"
		return_code=1
	fi

	return "${return_code}"
}
