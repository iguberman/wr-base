#!/bin/bash
#
# Copyright (c) 2014 Wind River Systems
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

# ------------------------------------------------------------------------
# A tool to compare the results of different ptest runs.  This script assumes
# that the input will be a raw log of the ptest run, in the style produced by
# using the start-ptest makefile target on build server or the ptest-run tool
# on target. The input can also be the summary ptest results generated by the
# ptest-summary.sh tool with options "-d -f". But the summary ptest results
# produced by ptest-summary.sh tool only with "-s" or "-d" isn't accepted.

ret=0
verbose=0
ptest_detail_failures=0
ptest_base_pkgs=""
ptest_tested_pkgs=""

function usage
{
    cat <<-EOF
Usage: $0 [options] FILE1 FILE2
Compare the results of different ptest runs.

Options:
  -d         Show the detailed failures for the failed ptests
  -v         Verbose mode, show all section headers and test statistics
  -h         help and usage information (this message)

FILE1 is the basic ptest log for comparison.
FILE2 is the new ptest log to be checked.
EOF
}

function debug_echo
{
    [ x"$DEBUG" = x1 ] && echo "[Debug] $*"
}

function get_ptest_list
{
    local ptest_run_log=$1
    #Get the ptest list from the raw or summary ptest log
    if grep -q "^START: .*ptest-runner" ${ptest_run_log}; then
        grep "^BEGIN:" ${ptest_run_log} | awk '{ print $2 }'
    else
        grep "/ptest$" ${ptest_run_log}
    fi
}

function get_ptest_pkg_result
{
    local ptest_run_log=$1
    local pkg_name=$2
    local t_pass
    local t_fail
    if grep -q "^START: .*ptest-runner" ${ptest_run_log}; then
        t_pass=$(sed -n "/BEGIN: .*\/${pkg_name}\/ptest/,/END: .*\/${pkg_name}\/ptest/p" ${ptest_run_log} \
               | grep -c "^PASS:")
        t_fail=$(sed -n "/BEGIN: .*\/${pkg_name}\/ptest/,/END: .*\/${pkg_name}\/ptest/p" ${ptest_run_log} \
               | grep -c "^FAIL:")
    else
        t_pass=$(sed -n "/\/${pkg_name}\/ptest/,/Skipped:/p" ${ptest_run_log} \
               | grep "Passed:" | awk -F: '{print $2}')
        t_fail=$(sed -n "/\/${pkg_name}\/ptest/,/Skipped:/p" ${ptest_run_log} \
               | grep "Failed:" | awk -F: '{print $2}')
    fi
    if [ $t_fail -ne 0 ]; then
        echo "FAILED"
    elif [ $t_pass -ne 0 ]; then
        echo "PASSED"
    else
        echo "SKIPPED"
    fi
}

function get_ptest_pkg_failures
{
    local ptest_run_log=$1
    local pkg_name=$2
    if grep -q "^START: .*ptest-runner" ${ptest_run_log}; then
        sed -n "/BEGIN: .*\/${pkg_name}\/ptest/,/END: .*\/${pkg_name}\/ptest/p" ${ptest_run_log} \
        | grep "^FAIL:" | sed -e '/BEGIN:/d' -e '/END:/d' | sed 's/^ *//g'
    else
        sed -n "/\/${pkg_name}\/ptest/,/Skipped:/p" ${ptest_run_log} \
        | grep "FAIL:" | sed -e '/\/${pkg_name}\/ptest/d' -e '/Skipped:/d' \
        | sed 's/^ *//g'
    fi
}

function get_testcases_summary
{
    old_case_pass_cn=0
    old_case_fail_cn=0
    old_case_skip_cn=0
    new_case_pass_cn=0
    new_case_fail_cn=0
    new_case_skip_cn=0
    if grep -q "^START: .*ptest-runner" ${ptest_base_log}; then
        old_case_pass_cn=$(grep -c ^PASS: ${ptest_base_log})
        old_case_fail_cn=$(grep -c ^FAIL: ${ptest_base_log})
        old_case_skip_cn=$(grep -c ^SKIP: ${ptest_base_log})
    else
        for i in $(grep "Passed:" $ptest_base_log | sed 's/Passed://g' | xargs); do
            old_case_pass_cn=$(($old_case_pass_cn + $i))
        done
        for i in $(grep "Failed:" $ptest_base_log | sed 's/Failed://g' | xargs); do
            old_case_fail_cn=$(($old_case_fail_cn + $i))
        done
        for i in $(grep "Skipped:" $ptest_base_log | sed 's/Skipped://g' | xargs); do
            old_case_skip_cn=$(($old_case_skip_cn + $i))
        done
    fi
    if grep -q "^START: .*ptest-runner" ${ptest_new_log}; then
        new_case_pass_cn=$(grep -c ^PASS: ${ptest_new_log})
        new_case_fail_cn=$(grep -c ^FAIL: ${ptest_new_log})
        new_case_skip_cn=$(grep -c ^SKIP: ${ptest_new_log})
    else
        for i in $(grep "Passed:" $ptest_new_log | sed 's/Passed://g' | xargs); do
            new_case_pass_cn=$(($new_case_pass_cn + $i))
        done
        for i in $(grep "Failed:" $ptest_new_log | sed 's/Failed://g' | xargs); do
            new_case_fail_cn=$(($new_case_fail_cn + $i))
        done
        for i in $(grep "Skipped:" $ptest_new_log | sed 's/Skipped://g' | xargs); do
            new_case_skip_cn=$(($new_case_skip_cn + $i))
        done
    fi
}

function print_package
{
    for p in $*; do echo $p/ptest | sed 's/^/        /g'; done
}

function print_package_failures
{
    for p in $*; do
        echo $p/ptest | sed 's/^/        /g'
        get_ptest_pkg_failures $ptest_new_log $p \
        | sed 's/^/            /g'
    done
}

function report_diff
{
    [ $# -ne 2 ] && usage && exit 2
    ptest_base_log=$1
    ptest_new_log=$2

    [ x"$verbose" = x1 ] && echo "Base ptest log file: ${ptest_base_log}"
    [ x$(readlink -f ${ptest_new_log}) = x$(readlink -f ${ptest_base_log}) ] && {
        echo "Error: $ptest_new_log is actually the same file of base ptest log"
        exit 2
    }

    for x in $(get_ptest_list ${ptest_base_log}); do
        ptest_base_pkgs+=" $(basename $(dirname $x))"
    done
    [ x"$ptest_base_pkgs" = x ] && {
        echo "Error: Find no ptest from log file: ${ptest_base_log}"
        exit 2
    }
    debug_echo "ptest_base_pkgs: $ptest_base_pkgs"

    [ x"$verbose" = x1 ] && echo "Processing ptest log file: $ptest_new_log"
    for x in $(get_ptest_list ${ptest_new_log}); do
        ptest_tested_pkgs+=" $(basename $(dirname $x))"
    done
    [ x"$ptest_tested_pkgs" = x ] && {
        echo "Error: Find no ptest from log file: ${ptest_new_log}"
        exit 2
    }
    debug_echo "ptest_tested_pkgs: $ptest_tested_pkgs"

    # the existing ptests are cases got from the base log file
    # process the existing ptests and get new passed or failed case
    exist_pkgs_new_pass=""
    exist_pkgs_new_fail=""
    exist_pkgs_new_skip=""
    pkg_missing=""
    old_pass_cn=0
    old_fail_cn=0
    old_skip_cn=0
    new_pass_cn=0
    new_fail_cn=0
    new_skip_cn=0
    for package in $ptest_base_pkgs; do
        debug_echo "package: $package"
        old_result=$(get_ptest_pkg_result ${ptest_base_log} ${package})
        debug_echo "old_result: $old_result"
        if echo $ptest_tested_pkgs | grep -q "\<$package\>"; then
            new_result=$(get_ptest_pkg_result ${ptest_new_log} ${package})
            debug_echo "new_result: $new_result"
            if [ x"$old_result" = xPASSED ]; then
                old_pass_cn=$(($old_pass_cn + 1))
                if [ x"$new_result" = xPASSED ]; then
                    new_pass_cn=$(($new_pass_cn + 1))
                elif [ x"$new_result" = xFAILED ]; then
                    new_fail_cn=$(($new_fail_cn + 1))
                    exist_pkgs_new_fail+=" $package"
                    ret=1
                elif [ x"$new_result" = xSKIPPED ]; then
                    new_skip_cn=$(($new_skip_cn + 1))
                    exist_pkgs_new_skip+=" $package"
                    ret=1
                fi
            elif [ x"$old_result" = xFAILED ]; then
                old_fail_cn=$(($old_fail_cn + 1))
                if [ x"$new_result" = xPASSED ]; then
                    new_pass_cn=$(($new_pass_cn + 1))
                    exist_pkgs_new_pass+=" $package"
                    ret=1
                elif [ x"$new_result" = xFAILED ]; then
                    new_fail_cn=$(($new_fail_cn + 1))
                elif [ x"$new_result" = xSKIPPED ]; then
                    new_skip_cn=$(($new_skip_cn + 1))
                    exist_pkgs_new_skip+=" $package"
                    ret=1
                fi
            elif [ x"$old_result" = xSKIPPED ]; then
                old_skip_cn=$(($old_skip_cn + 1))
                if [ x"$new_result" = xPASSED ]; then
                    new_skip_cn=$(($new_pass_cn + 1))
                    exist_pkgs_new_pass+=" $package"
                    ret=1
                elif [ x"$new_result" = xFAILED ]; then
                    new_fail_cn=$(($new_fail_cn + 1))
                    exist_pkgs_new_skip+=" $package"
                    ret=1
                elif [ x"$new_result" = xSKIPPED ]; then
                    new_skip_cn=$(($new_skip_cn + 1))
                fi
            fi
        else
            pkg_missing+=" $package"
            ret=1
            debug_echo "new_result: N/A"
            if [ x"$old_result" = xPASSED ]; then
                old_pass_cn=$(($old_pass_cn + 1))
            elif [ x"$old_result" = xFAILED ]; then
                old_fail_cn=$(($old_fail_cn + 1))
            elif [ x"$old_result" = xSKIPPED ]; then
                old_skip_cn=$(($old_skip_cn + 1))
            fi
        fi
    done

    # the new ptests are additional to the base ptest log
    # process the new ptests and get results
    new_pkgs_pass=""
    new_pkgs_fail=""
    new_pkgs_skip=""
    for package in $ptest_tested_pkgs; do
        if echo $ptest_base_pkgs | grep -q "\<$package\>"; then
            # skip the ptests that has been processed above
            continue
        else
            debug_echo "package: $package"
            result=$(get_ptest_pkg_result ${ptest_new_log} ${package})
            debug_echo "result: $result"
            if [ x"$result" = xPASSED ]; then
                new_pkgs_pass+=" $package"
                new_pass_cn=$(($new_pass_cn + 1))
                ret=1
            elif [ x"$result" = xFAILED ]; then
                new_pkgs_fail+=" $package"
                new_fail_cn=$(($new_fail_cn + 1))
                ret=1
            else
                new_pkgs_skip+=" $package"
                new_skip_cn=$(($new_skip_cn + 1))
                ret=1
            fi
        fi
    done

    # print the diff of ptest results
    [ x"$verbose" = x1 ] || [ -n "$exist_pkgs_new_pass" ] && {
        echo "---- The ptests previously are FAILED or SKIPPED, currently are PASSED ----"
        print_package $exist_pkgs_new_pass
    }

    [ x"$verbose" = x1 ] || [ -n "$exist_pkgs_new_fail" ] && {
        echo "---- The ptests previously are PASSED or SKIPPED, currently are FAILED ----"
        if [ x"$ptest_detail_failures" = x1 ]; then
            print_package_failures $exist_pkgs_new_fail
        else
            print_package $exist_pkgs_new_fail
        fi
    }

    [ x"$verbose" = x1 ] || [ -n "$exist_pkgs_new_skip" ] && {
        echo "---- The ptests previously are PASSED or FAILED, currently are SKIPPED ----"
        print_package $exist_pkgs_new_skip
    }

    [ x"$verbose" = x1 ] || [ -n "$pkg_missing" ] && {
        echo "---- The ptests which are missing ----"
        print_package $pkg_missing
    }

    [ x"$verbose" = x1 ] || [ -n "$new_pkgs_pass" ] && {
        echo "---- The new ptests which are PASSED ----"
        print_package $new_pkgs_pass
    }

    [ x"$verbose" = x1 ] || [ -n "$new_pkgs_fail" ] && {
        echo "---- The new ptests which are FAILED ----"
        if [ x"$ptest_detail_failures" = x1 ]; then
            print_package_failures $new_pkgs_fail
        else
            print_package $new_pkgs_fail
        fi
    }

    [ x"$verbose" = x1 ] || [ -n "$new_pkgs_skip" ] && {
        echo "---- The new ptests which are SKIPPED ----"
        print_package $new_pkgs_skip
    }

    [ x"$verbose" = x1 ] && {
        get_testcases_summary
        echo -e "\n---- Statistics summary ----"
        printf "%-25s%-8s%s\n" "The ptest results:" "Base" "New"
        printf "%-25s%-8d%d\n" "Passed ptest suites:" $old_pass_cn $new_pass_cn
        printf "%-25s%-8d%d\n" "Failed ptest suites:" $old_fail_cn $new_fail_cn
        printf "%-25s%-8d%d\n" "Skipped ptest suites:" $old_skip_cn $new_skip_cn
        printf "%-25s%-8d%d\n" "Passed ptest cases:" $old_case_pass_cn $new_case_pass_cn
        printf "%-25s%-8d%d\n" "Failed ptest cases:" $old_case_fail_cn $new_case_fail_cn
        printf "%-25s%-8d%d\n" "Skipped ptest cases:" $old_case_skip_cn $new_case_skip_cn
    }
}

# main
files=""
for opt in "$@"; do
    case $opt in
        -d ) ptest_detail_failures=1 ;;
        -v ) verbose=1 ;;
        -h ) usage ; exit 0 ;;
        -* ) echo "$opt: Invalid option" ; usage ; exit 2 ;;
        *  ) files+=" $opt" ;;
    esac
done

# sanity check the ptest logs
if [ -z "${files}" ]; then
    echo "No log file is specified."
    usage
    exit 2
fi
for f in ${files}; do
    if [ ! -e ${f} ]; then
        echo "${f} does not appear to be a log file"
        exit 2
    fi

    if [ ! -r ${f} ]; then
        echo "${f} is not readable"
        exit 2
    fi

    if ! (grep -q "^BEGIN: .*ptest" $f) && ! (grep -A1 "/ptest" $f | grep -q "Passed"); then
        echo "${f} does not appear to be a valid ptest log file"
        echo "A valid ptest log file should only be one of the following:"
        echo "    a) The raw ptest log, like: ptest-run-2014-07-24T17:50.log"
        echo "    b) The summary log produced by ptest-summary.sh with options '-d -f'"
        exit 2
    fi
done

report_diff $files
exit $ret
