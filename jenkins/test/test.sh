#!/bin/bash
# Usage: test.sh
# This script is from the "Passenger RPM packaging test" Jenkins job. It builds
# packages for a specific distribution and runs tests on these packages.
#
# Required environment variables:
#
#   WORKSPACE
#   DISTRIBUTION
#
# Optional environment variables:
#
#   PASSENGER_ROOT (defaults to $WORKSPACE)
#   ENTERPRISE
#
# Sample invocation in Vagrant dev environment:
#
#   env WORKSPACE=$HOME DISTRIBUTION=el7 PASSENGER_ROOT=/passenger ./jenkins/test/test.sh

set -e
SELFDIR=`dirname "$0"`
cd "$SELFDIR/../.."
source "./internal/lib/library.sh"
source "./internal/lib/distro_info.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar DISTRIBUTION "$DISTRIBUTION"

PASSENGER_ROOT="${PASSENGER_ROOT:-$WORKSPACE}"
CONCURRENCY=${CONCURRENCY:-4}

TEST_DISTRO_NAME=`el_name_to_distro_name "$DISTRIBUTION"`
if [[ "$DEBUG_CONSOLE" = true ]]; then
	EXTRA_TEST_PARAMS=-D
else
	EXTRA_TEST_PARAMS=
fi
if [[ "$ENTERPRISE" = 1 ]]; then
	EXTRA_TEST_PARAMS="$EXTRA_TEST_PARAMS -e $HOME/passenger-enterprise-license"
fi

# Sleep for a random amount of time in order to work around Docker/AUFS bugs
# that may be triggered if multiple containers are shut down at the same time.
echo 'import random, time; time.sleep(random.random() * 4)' | python

run ./build \
	-w "$WORKSPACE/work" \
	-c "$WORKSPACE/cache" \
	-o "$WORKSPACE/output" \
	-p "$PASSENGER_ROOT" \
	-d "$DISTRIBUTION" \
	-a x86_64 \
	-j "$CONCURRENCY" \
	-R \
	-O \
	rpm:all
run ./test \
	-p "$PASSENGER_ROOT" \
	-d "$WORKSPACE/output/$DISTRIBUTION" \
	-c "$WORKSPACE/cache" \
	-x "$TEST_DISTRO_NAME" \
	-j \
	$EXTRA_TEST_PARAMS
