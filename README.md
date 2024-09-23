<img width="249" alt="prog4eng" src="https://user-images.githubusercontent.com/49416778/176197400-31ae2f49-6f28-4035-8483-a02fba8fe3db.png">

Small Matlab test runner that tests functions of students.

Is quite minimal and everything should be well described in the file `test.m`.

A test can:

- _pass_, everything works as intended (correct output or expected error)
- _fail_, does not succeed (wrong output or did not raise an error)
- _error_, raises an unexpected error
- _timeout_, takes longer than expected

The following *constants* can be modified
- `TIMEOUT_TRESH`, time until test times out
- `ABS_TOL`, absolute tolerance when comparing numbers
- `REL_TOL`, relative tolerance when comparing numbers

For comparing numbers the code was adapted from [this function](https://docs.python.org/3/library/math.html#math.isclose) &rarr; see there for an explanation for `ABS_TOL`, `REL_TOL`.

For adding new test cases, pass an anonymous function to `test_function` with the expected return value of the function. Again see `test.m` for examples.

See below a test run, with a function of an exercise from 2023.


```matlab
>>> test
          input                                              output       expected    
[PASSED]  findRootByBisection(@(x)x,-1,1)                    0            0
[FAILED]  findRootByBisection(@(x)x,-1,1)                    0            1
[PASSED]  findRootByBisection(@(x)x,1,2)                     error        error
[FAILED]  findRootByBisection(@(x)x,-1,1)                    0            error
[ERROR]   findRootByBisection(@(x)x,1,2)                     error        0
[PASSED]  [1,2;3,4]                                          [1,2;3,4]    [1,2;3,4]
[TIMEOUT] infinite_loop()                                    timeout      0 
```

