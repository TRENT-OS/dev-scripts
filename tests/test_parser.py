import pytest, re, time

# Copyright (C) 2020-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net

def find_assert(output_file):
    """
    Check if current output already contains an assert failure of any type. Start
    at the beginning and ensure that we set the file cursor back.
    """
    assert_re = re.compile(r'Assertion failed: \@(.*)\((.*)\): (.*)\n')
    test_fn = None
    output_file.seek(0,0)
    while True:
        line = output_file.readline()
        if line.endswith("\n"):
            mo = assert_re.search(line)
            if mo != None:
                test_fn = mo.group(1)
                break
        else:
            break
    output_file.seek(0,0)
    return test_fn

def check_result_or_assert(output_file, test_fn, test_args, timeout=0):
    """
    Wait for a test result string or an assert specific to a test function appears
    in the output file.
    """
    test_name = test_fn if test_args == None else "%s(%s)" % (test_fn, test_args)
    assert_re = re.compile(r'Assertion failed: @%s: (.*)\n' % re.escape(test_name))
    result_re = re.compile(r'!!! %s: OK\n' % re.escape(test_name))

    stop_time = time.time() + timeout
    line = ""

    while True:
        line += output_file.readline()
        if line.endswith("\n"):
            mo = result_re.search(line)
            if mo != None:
                return (True, None)
            mo = assert_re.search(line)
            if mo != None:
                return (False, mo.group(1))
            line = ""
        else:
            time.sleep(0.1)
            if time.time() > stop_time:
                return (False, None)

def check_test(test_run, timeout, test_fn, test_args=None, single_thread=True):
    """
    The strategy to check the test results for cases where there is only a single
    test thread (single_thread=True) is as follows:
        1. If there was already a failure, check if test result is still there but do
           not wait for it.
        2. If there was no failure yet, wait for test result or a failure specific
           to the test we are looking at.
        3. If the test result is not found, we may be in any of these situations:
            a. The test we are currently checking failed with an assertion
            b. A different test failed with an assertion and thus stopped the entire
               test run
            c. No assertion of any kind was found, so we have a timeout due to other
               reasons
    If there is more than one test thread (single_thread=False), an assertion for one test
    may not block other tests from completing. Therefore we skip step (1.) and always
    wait for the correct test result to appear (or its corresponding assertion).
    """
    __tracebackhide__ = True
    failed_fn = find_assert(test_run[1]) if single_thread else None
    if not failed_fn:
        test_ok, test_assert = check_result_or_assert(test_run[1], test_fn, test_args, timeout)
    else:
        test_ok, test_assert = check_result_or_assert(test_run[1], test_fn, test_args)

    if not test_ok:
        if test_assert:
            pytest.fail(test_assert)
        else:
            if failed_fn:
                pytest.fail("Aborted because {} already failed".format(failed_fn))
            else:
                assert_msg = find_assert(test_run[1])
                if assert_msg:
                    pytest.fail("Timed out because {} failed".format(assert_msg))
                else:
                    pytest.fail("Timed out but no assertion was found")

