/**
 * Copyright (C) 2019-2020, Hensoldt Cyber GmbH
 */

#pragma once

#include "LibDebug/Debug.h"

#include <assert.h>
#include <string.h>

/**
 * @brief   Max test frameworks message length
 *
 * This is an arbitrary value chosen so that it is not too big i.e. does not
 * pollute the test logs and does not have a big impact on the test run time but
 * on the other hand can store the test name, message itself, the path, and
 * the line number.
 *
 * Feel free to increase it if there is a strong need, but the current value
 * should be more than enough.
 */
#define MAX_MSG_LEN 512

// We use this to keep track of the name of the test that is is currently being
// executed, see below...
static char testName[MAX_MSG_LEN] = "<undefined>";

/*
 * With the help of TEST_START() and TEST_FINISH() we can track which test is
 * currently running so we know the test's name in case an assertion is hit.
 *
 * TEST_START can take up to two arguments (which will be interpreted as int)
 * TEST_FINISH takes no arguments
 */

// With this trick, we can map between zero to two arguments to the respective
// "sub-macro" and use the appropriate format string.
#define SELECT_START(PREFIX, _2, _1, _0, SUFFIX, ...) PREFIX##_##SUFFIX
#define _TEST_START_STOP(...)                                                  \
  Debug_ASSERT_PRINTFLN(0, "Too many arguments for TEST_START.")
#define _TEST_START_2(arg0, arg1)                                              \
  snprintf(testName, sizeof(testName), "%s(%s=%i,%s=%i)", __func__, #arg0,     \
           (int)arg0, #arg1, (int)arg1)
#define _TEST_START_1(arg0)                                                    \
  snprintf(testName, sizeof(testName), "%s(%s=%i)", __func__, #arg0, (int)arg0)
#define _TEST_START_0(...) snprintf(testName, sizeof(testName), "%s", __func__)
#define TEST_START(...)                                                        \
  SELECT_START(_TEST_START, ##__VA_ARGS__, STOP, 2, 1, 0)(__VA_ARGS__)

// This outputs the tests name as a marker that it has been completed. Also, we
// reset the testName to make incorrect use of TEST_START/TEST_FINISH more easy
// to spot.
#define TEST_FINISH()                                                          \
{                                                                              \
    Debug_LOG_INFO("!!! %s: OK", testName);                                    \
    snprintf(testName, sizeof(testName), "<undefined>");                       \
}

#define ASSERT_COMPARE(expected, actual, operator) do                          \
{                                                                              \
    if(!(expected operator actual))                                            \
    {                                                                          \
        char msg[MAX_MSG_LEN];                                                 \
        const int ret = snprintf(                                              \
                            msg,                                               \
                            sizeof(msg),                                       \
                            "@%s: Comparison failure: %s " #operator " %s i.e."\
                            "%d " #operator " %d",                             \
                                testName,                                      \
                                #expected,                                     \
                                #actual,                                       \
                                expected,                                      \
                                actual);                                       \
                                                                               \
        if(ret>=sizeof(msg))                                                   \
        {                                                                      \
            printf("Message was truncated.\n");                                \
        }                                                                      \
                                                                               \
        __assert_fail(msg, __FILE__, __LINE__, __func__);                      \
    }                                                                          \
} while(0)

#define ASSERT_EQ(expected, actual) ASSERT_COMPARE(expected, actual, ==)
#define ASSERT_NE(expected, actual) ASSERT_COMPARE(expected, actual, !=)

#define ASSERT_LT(expected, actual) ASSERT_COMPARE(expected, actual, <)
#define ASSERT_LE(expected, actual) ASSERT_COMPARE(expected, actual, <=)

#define ASSERT_GT(expected, actual) ASSERT_COMPARE(expected, actual, >)
#define ASSERT_GE(expected, actual) ASSERT_COMPARE(expected, actual, >=)

/**
 * With the help of these TEST_xxx we obtain practical shorthands for checking
 * a function result agains OS_Error_t error codes.
 *
 * Furthermore (and more importantly), we can define and use our own assertions,
 * so that we can add the name of the test to a failing assertion. This is
 * useful if the assert does not fail in the test function itself, but in a
 * function called by the test (in this case, assert does not give the test
 * function name but the name of the subfunction).
 */

// These shorthands can be used to simply check function return codes
#define TEST_INSUFF_SPACE(fn)   ASSERT_EQ(OS_ERROR_INSUFFICIENT_SPACE,  fn)
#define TEST_TOO_SMALL(fn)      ASSERT_EQ(OS_ERROR_BUFFER_TOO_SMALL,    fn)
#define TEST_ABORTED(fn)        ASSERT_EQ(OS_ERROR_ABORTED,             fn)
#define TEST_OP_DENIED(fn)      ASSERT_EQ(OS_ERROR_OPERATION_DENIED,    fn)
#define TEST_ACC_DENIED(fn)     ASSERT_EQ(OS_ERROR_ACCESS_DENIED,       fn)
#define TEST_NOT_FOUND(fn)      ASSERT_EQ(OS_ERROR_NOT_FOUND,           fn)
#define TEST_INVAL_HANDLE(fn)   ASSERT_EQ(OS_ERROR_INVALID_HANDLE,      fn)
#define TEST_INVAL_NAME(fn)     ASSERT_EQ(OS_ERROR_INVALID_NAME,        fn)
#define TEST_INVAL_PARAM(fn)    ASSERT_EQ(OS_ERROR_INVALID_PARAMETER,   fn)
#define TEST_NOT_SUPP(fn)       ASSERT_EQ(OS_ERROR_NOT_SUPPORTED,       fn)
#define TEST_GENERIC(fn)        ASSERT_EQ(OS_ERROR_GENERIC,             fn)
#define TEST_SUCCESS(fn)        ASSERT_EQ(OS_SUCCESS,                   fn)

// Check boolean expression and not an error code
// Checking return value of snprintf to stop GCC from throwing error about
// format truncation.
#define TEST_TRUE(st)                                                          \
{                                                                              \
    char msg[MAX_MSG_LEN];                                                     \
    int ret = snprintf(msg, sizeof(msg), "@%s: %s", testName, #st);            \
    if(ret>=sizeof(msg)) { /*Message was truncated */};                        \
    ((void)((st) || (__assert_fail(msg, __FILE__, __LINE__, __func__), 0)));   \
}
