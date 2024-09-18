% Trial for some testrunner for Prog4Eng
% - test is the test-harness for the function, see examples written there
% - functions in CAPS are used as constant values
% - test_function is the organizer of everything
% - run_function runs the function and returns result and if function finished
% - test_equal is function that tests equality for string, char, and double arrays
% - isclose is function that tests if two float-values are close to each other
% - stringify turns an array to a string for a nicer output.

% It is not a lot of code, I tried my best to make it readable.

% Possible Extensions:
% - Functions so far can only return one value (which is okay in most cases)
% - Only supports arrays as output so far.
%   Because test_equal function will fail on nested types,
%   and stringify assumes arrays as input.
% - Add a way to test output of a script instead of a function
% - The output of a line is a bit limited, especially outout and expected,
%   it is not given that they fit into their space.

% Maybe move abs_tol, rel_tol to constants instead of arguments to the function

function test()
    % clc; % maybe clc is annyoing for the students
    print_header();

    % test should pass
    test_function(@() findRootByBisection(@(x) x, -1, 1), 0)
    % test should fail as output ~= expected 
    test_function(@() findRootByBisection(@(x) x, -1, 1), 1)
    % test should pass as function throws error
    test_function(@() findRootByBisection(@(x) x, 1, 2), 0, should_fail=true)
    % test should fail as function fails to throw error
    test_function(@() findRootByBisection(@(x) x, -1, 1), 0, should_fail=true);
    % test should error as function throws unexpected error
    test_function(@() findRootByBisection(@(x) x, 1, 2), 0)
    % test should pass (with generous abs_tol)
    test_function(@() [1, 2; 3, 4], [2, 3; 4, 5], abs_tol=1.0);
    % test should timeout as function does not finish on time
    test_function(@() infinite_loop(), 0);
end

% Define enum for return value of run_function
function val = STATUS_FINISHED
    val = 0;
end
function val = STATUS_ERROR
    val = 1;
end
function val = STATUS_TIMEOUT
    val = 2;
end

% Define constant for run_function
function val = TIMEOUT_TRESH
    % timeout time for function in seconds
    val = 0.5;
end

function answer = infinite_loop()
    answer = 0; %#ok<NASGU>
    while true
    end
end

function print_header()
    fprintf("          ");
    fprintf("%-50s %-12s %-12s", "input", "output", "expected");
    fprintf("\n");
end

function test_function(f, expected, kwargs)
    % Test if function generates expected output and writes result to terminal.
    %
    % Numbers are compared with `isclose` functions all other outputs with `isequal`
    %
    % Parameters
    % ----------
    % f: function_handle
    %     Function to be tested against output.
    % expected: any
    %     Expected output, nested data cells and such are not really supported.
    % kwargs.should_fail: logical, default false
    %     Note if function should fail in this case.
    %     Expected gets ignored if set to true.
    % kwargs.rel_tol: double
    %     Relative tolerance for comparing numbers.
    % kwargs.abs_tol: double
    %     Absolute tolerance for comparing numbers.
    arguments
        f (1, 1) function_handle
        expected
        kwargs.should_fail (1, 1) logical = false
        kwargs.rel_tol (1, 1) double = 1e-09
        kwargs.abs_tol (1, 1) double = 0.0
    end
    % Values of result (only local to this function)
    % I wish enums would not require an extra file :(
    PASSED = 0; % function returned & correct result
    FAILED = 1; % function returned & false result
    ERROR = 2; % function raised an error
    TIMEOUT = 3; % function did not return on time

    [answer, status] = run_function(f);

    % ignore expected
    if kwargs.should_fail
        expected = "error";
    end

    switch status
        case STATUS_TIMEOUT
            result = TIMEOUT;

        case STATUS_ERROR
            if kwargs.should_fail
                result = PASSED;
            else
                result = ERROR;
            end

        case STATUS_FINISHED
            if kwargs.should_fail
                result = FAILED;
            elseif test_equal(answer, expected, kwargs.rel_tol, kwargs.abs_tol)
                result = PASSED;
            else
                result = FAILED;
            end

        otherwise
            error("invalid status");
    end

    %% Print to output
    % 1 is stdout
    % 2 is stderr
    % We (ab)use the fact that Matlab prints stderr red in terminal.
    switch result
        case PASSED
            fprintf(1, "[PASSED]  ");
        case FAILED
            fprintf(2, "[FAILED]  ");
        case ERROR
            fprintf(2, "[ERROR]   ");
        case TIMEOUT
            fprintf(2, "[TIMEOUT] ");
        otherwise
            error("invalid result");
    end

    func = func2str(f);
    func = func(4:end); % get rid of `@()` at start
    answer = stringify(answer);
    expected = stringify(expected);

    % Maybe change this magic sizes?
    fprintf("%-50s %-12s %-12s", func, answer, expected);
    fprintf("\n");

end

function [answer, status] = run_function(f)
    % answer is return value of function
    % status is one of the following STATUS_ + {FINISHED, ERROR, TIMEOUT}
    % if status = {ERROR, TIMEOUT} then answer is {"error", "timeout"} respectively
    try
        fut = parfeval(backgroundPool, f, 1);
        ok = fut.wait('finished', TIMEOUT_TRESH);

        if ok
            answer = fetchOutputs(fut);
            status = STATUS_FINISHED;
        else
            cancel(fut);
            answer = "timeout";
            status = STATUS_TIMEOUT;
        end

    catch
        answer = "error";
        status = STATUS_ERROR;
    end

end

function answer = test_equal(a, b, rel_tol, abs_tol)
    % if both arrays are number test via isclose
    % else just go with exact equality.

    % simple equality test first that simplifies other stuff
    if ~isequal(size(a), size(b)) || ~isequal(class(a), class(b))
        answer = false;
    elseif isnumeric(a)
        answer = true;
        for k = 1:numel(a)
            answer = answer && isclose(a(k), b(k), rel_tol, abs_tol);
        end
    else
        answer = isequal(a, b);
    end
end

function answer = isclose(a, b, rel_tol, abs_tol)
    % This function is the copied from the cpython implementation:
    % https://docs.python.org/3/library/math.html#math.isclose

    % sanity check on the inputs
    if rel_tol < 0.0 || abs_tol < 0.0
        error("tolerance must be non-negative");
    end

    if a == b
        % short circuit exact equality, catches two infinities of the same sign
        answer = true;
        return;
    end

    %  This catches the case of two infinities of opposite sign, or
    %  one infinity and one finite number. Two infinities of opposite
    %  sign would otherwise have an infinite relative tolerance.
    %  Two infinities of the same sign are caught by the equality check
    %  above.
    if isinf(a) || isinf(b)
        answer = false;
        return;
    end

    diff = abs(b - a);

    answer = (diff <= abs(rel_tol * b));
    answer = answer || (diff <= abs(rel_tol * a));
    answer = answer || (diff <= abs_tol);
end

function str = stringify(a)
    % Creates a one-line string out of array a

    if isequal(size(a), [1, 1])
        str = string(a);
        return;
    end
    a = string(a);
    [nrows, ~] = size(a);
    rows = strings(nrows, 1);
    for row = 1:nrows
        rows(row) = strjoin(a(row, :), ", ");
    end
    str = "[" + strjoin(rows, "; ") + "]";
end
