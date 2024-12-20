% Run tests for the function programmed in the exercise
%
% To call just run the following in the script or the command window:
% test_findRootByBisection()

% Date: 2024
% Author: Christof Leutenegger
function test_findRootByBisection()
    print_header();
    test_function(@()findRootByBisection(@(x)x, -1, 1), 0);
    test_function(@()findRootByBisection(@(x)-x, -1, 1), 0);
    test_function(@()findRootByBisection(@(x)3 * x.^3 + 2 - exp(x), -1, 1), -0.80273);
    test_function(@()findRootByBisection(@(x)3 * x.^3 + 2 - exp(x), 0, 10), 6.8915);
    test_function(@()findRootByBisection(@(x)(x - 1) * (x + 3) * (x - 2), -5, 0), -3);
    test_function(@()findRootByBisection(@(x)(x - 1) * (x + 3) * (x - 2), -1, 1.5), 1);
    test_function(@()findRootByBisection(@(x)(x - 1) * (x + 3) * (x - 2), 1.5, 5), 2);
    test_function(@()findRootByBisection(@(x)(x - 1) * (x + 3) * (x - 2), -4, 4), -3);
    % test_function(@()findRootByBisection(@(x)x.^2 + 2 * x, -1, 1), 0);
    % test_function(@()findRootByBisection(@(x)x.^2 + 2 * x, -10, -1), -2);
    % test_function(@()findRootByBisection(@(x)1 / x, -1, 1), 0);
    test_function(@()findRootByBisection(@(x)sin(x), 1, pi+1), pi);
    test_function(@()findRootByBisection(@(x)x, 1, 2), 0, should_error=true);
    test_function(@()findRootByBisection(@(x)x.^2+1, -1, 1), 0, should_error=true);
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
    val = 0.0011;
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

%% Functions to run test

function print_header()
    fprintf("          ");
    fprintf(FMT_STR, "input", "expected", "output"); %#ok<CTPCT>
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
    %     Note if function should throw error.
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

    fprintf(FMT_STR, func, expected, answer);
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

    % simple equality test first that simplifies other stuff
    if ~isequal(size(a), size(b)) || ~isequal(class(a), class(b))
        answer = false;
    elseif isnumeric(a)
        answer = true;
        for k = 1:numel(a)
            answer = answer && isclose(a(k), b(k), REL_TOL, ABS_TOL);
        end
    else
        answer = isequal(a, b);
    end
end

function answer = isclose(a, b, rel_tol, abs_tol)
    % Copied from the cpython implementation:
    % https://docs.python.org/3/library/math.html#math.isclose
    arguments
        a (1, 1) double
        b (1, 1) double
        rel_tol (1, 1) double = 1e-9
        abs_tol (1, 1) double = 0.0
    end

    % This function could easily be vectorized but I decided
    % against that for clearity + correctness.

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
    % Creates a one-line string out of array

    if isequal(size(a), [1, 1])
        str = string(a);
    elseif iscell(a) || isstruct(a) || istabular(a)
        % hack a bit to avoid errors while stringifying student results.
        % maybe replace with proper recursive string creation :)
        % https://stackoverflow.com/questions/12799161/is-there-a-matlab-function-to-convert-any-data-structure-to-a-string
        str = strip(evalc('disp(a)'));
    else
        a = string(a);
        [nrows, ~] = size(a);
        rows = strings(nrows, 1);
        for row = 1:nrows
            rows(row) = strjoin(a(row, :), ",");
        end
        str = "[" + strjoin(rows, ";") + "]";
    end
end
