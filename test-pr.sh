#!/bin/bash

# Test a https://github.com/gentoo/gentoo pull request, for example:
# Input: test-pr.sh 12345
# Would test https://github.com/gentoo/gentoo/pull/12345
#
# Input options:
#   -1: runs a single build test. Useful for testing minor fixes.
#    test-pr.sh -1 12345
#
#   -i: interactive. Spawn a shell before launching tests, if need to modify
#       the ebuild somehow for example. Will merge the patch, call
#       "prtester.sh" manually afterwards.
#    test-pr.sh -i 12345
#
#   (null): runs the default test suite.
#   test-pr.sh 12345
#

if [[ -z ${1} ]]; then
	echo "Please insert a GitHub PR number!"
	echo "https://github.com/gentoo/gentoo/pull/<this_one>"
	exit
fi

main() {
	local run=""
	local prId=""

	while [[ ${#} -gt 0 ]]; do
		case ${1} in
			-i)
				run="i"
				prId="${2}"
				;;
			*)
				prId="${1}"
				;;
		esac
		shift
	done

	TESTING="tester-${prId}"

	echo "Initializing new test environment... this will take a while."
	lxc copy tester "${TESTING}"
	lxc start "${TESTING}"
	lxc exec "${TESTING}" -- su -lc "(sleep 10 && cd /var/db/repos/gentoo && curl -s -L https://patch-diff.githubusercontent.com/raw/gentoo/gentoo/pull/${prId}.patch | git -c user.email=mscardovi@icloud.com -c user.name='Marco Scardovi' am --keep-cr -3)"

	if [[ -z "${run}" ]]; then
		echo "INFO: Doing the default test runs."
		lxc exec "${TESTING}" -- su -lc "(sleep 10 && sed -i -e 's/--max-use-combinations 6/--max-use-combinations 1/g' /root/lxd-bin/container/bin/prtester.sh)"
		lxc exec "${TESTING}" -- su -lc "(sleep 10 && ~/lxd-bin/container/bin/prtester.sh)"
		lxc exec "${TESTING}" -- su -lc "(~/lxd-bin/container/bin/errors_and_qa_notices.sh)"
		lxc exec "${TESTING}" bash

	elif [[ "${run}" == "i" ]]; then
		echo "INFO: -i invoked - entering interactive mode."
		lxc exec "${TESTING}" bash

	else
		echo "ERROR: Not sure what to do here. Insert proper inputs. Check help."
		exit

	fi

	lxc exec "${TESTING}" -- su -lc "(sleep 10 && pfl &>/dev/null)"
	lxc stop "${TESTING}"
}

main "${@}"
