% Run tests for the function programmed in the exercise
%
% To call just run the following in the script or the command window:
% test()

% Experiment for a testrunner for Prog4Eng
% Date: 2024
% Author: Christof Leutenegger
% It is not a lot of code, I tried my best to make it readable. :)

% Short description for all functions as an overview
% - `test` is the test-harness/test-runner, see there for examples.
% - functions in CAPS are used as constant values.
% - `test_function` runs a test and prints the output
% - `run_function` runs function, returns result and if function finished.
% - `test_equal`, `is_close`, `stringify` are smaller helper functions

% Possible Extensions / Limitations:
% - Functions so far can only return one value (which is okay in most cases)
% - Only supports arrays as output so far (includes scalars). Because test_equal
%   will fail on nested types, and stringify assumes arrays as input.
% - The horizontal space in the terminal is limited, this can be a problem if
%   expected and output value are too big.

function test()
    print_header();

    % test should pass
    test_function(@() findRootByBisection(@(x) x, -1, 1), 0)
    % test should fail as output ~= expected
    test_function(@() findRootByBisection(@(x) x, -1, 1), 1)
    % test should pass as function throws error
    test_function(@() findRootByBisection(@(x) x, 1, 2), 0, should_error=true)
    % test should fail as function fails to throw error
    test_function(@() findRootByBisection(@(x) x, -1, 1), 0, should_error=true);
    % test should error as function throws unexpected error
    test_function(@() findRootByBisection(@(x) x, 1, 2), 0)
    % test should pass (is within rel_tol)
    test_function(@() [1, 2; 3, 4], [1 + 1e-10, 2 + 2e-10; 3 + 3e-10, 4 + 4e-10]);
    % test should timeout as function does not finish on time
    test_function(@() infinite_loop(), 0);
end

%% Global constants
function val = TIMEOUT_TRESH
    % timeout time for function in seconds
    val = 4.0;
end
function val = REL_TOL
    % Relative tolerance for comparing numbers.
    % see https://docs.python.org/3/library/math.html#math.isclose
    val = 1e-09;
end
function val = ABS_TOL
    % Absolute tolerance for comparing numbers.
    % see https://docs.python.org/3/library/math.html#math.isclose
    val = 0.0;
end
function val = FMT_STR
    val = "%-50s %-12s %-12s";
end

%% Enum for `run_function` return values
function val = STATUS_FINISHED
    val = 0;
end
function val = STATUS_ERROR
    val = 1;
end
function val = STATUS_TIMEOUT
    val = 2;
end

%% Function to show timeout mechanic
function answer = infinite_loop()
    answer = 0; %#ok<NASGU>
    while true
    end
end

%% Functions to run test

function print_header()
    fprintf("          ");
    fprintf(FMT_STR, "input", "output", "expected"); %#ok<CTPCT>
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
    % kwargs.should_error: logical, default false
    %     Note if function should fail in this case.
    %     Expected gets ignored if set to true.
    arguments
        f (1, 1) function_handle
        expected
        kwargs.should_error (1, 1) logical = false
    end
    % Values of result (only local to this function)
    % I wish enums would not require an extra file :(
    PASSED = 0; % function returned & correct result
    FAILED = 1; % function returned & false result
    ERROR = 2; % function raised an error
    TIMEOUT = 3; % function did not return on time

    [answer, status] = run_function(f);

    % ignore expected
    if kwargs.should_error
        expected = "error";
    end

    switch status
        case STATUS_TIMEOUT
            result = TIMEOUT;

        case STATUS_ERROR
            if kwargs.should_error
                result = PASSED;
            else
                result = ERROR;
            end

        case STATUS_FINISHED
            if kwargs.should_error
                result = FAILED;
            elseif test_equal(answer, expected)
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

    fprintf(FMT_STR, func, answer, expected);
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

function answer = test_equal(a, b)
    % if both arrays are number test via isclose
    % else just go with exact equality.

    % first simple equality check that simplifies other tests
    % then handling of composite types recursively
    % then fallback to isequal
    if ~isequal(size(a), size(b)) || ~isequal(class(a), class(b))
        answer = false;

    elseif isfloat(a)
        answer = true;
        for k = 1:numel(a)
            answer = answer && isclose(a(k), b(k));
        end

    elseif iscell(a)
        answer = true;
        for k = 1:numel(a)
            answer = answer && test_equal(a{k}, b{k});
        end

    elseif isstruct(a)
        fields = fieldnames(a);
        if ~isequal(fields, fieldnames(b))
            answer = false;
            return;
        end
        answer = true;

        for k = 1:numel(a)
            for fidx = numel(fields)
                answer = answer && test_equal(a(k).(fields(fidx)), b(k).fields(fidx));
            end
        end

    elseif istabular(a)
        warning("really tables? just use pandas or polar please");
        answer = isequal(a, b);
    else
        answer = isequal(a, b);
    end
end

function answer = isclose(a, b)
    % Copied from the cpython implementation:
    % https://docs.python.org/3/library/math.html#math.isclose

    % This function could easily be vectorized but I decided
    % against that for clearity + correctness.

    % sanity check on the inputs
    if REL_TOL < 0.0 || ABS_TOL < 0.0
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

    answer = (diff <= abs(REL_TOL * b));
    answer = answer || (diff <= abs(REL_TOL * a));
    answer = answer || (diff <= ABS_TOL);
end

function str = stringify(a)
    % Creates a one-line string out of array

    if isequal(size(a), [1, 1])
        str = string(a);
        return;
    end
    a = string(a);
    [nrows, ~] = size(a);
    rows = strings(nrows, 1);
    for row = 1:nrows
        rows(row) = strjoin(a(row, :), ",");
    end
    str = "[" + strjoin(rows, ";") + "]";
end
