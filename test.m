% Alternatively we could not print "output" and "expected"
% This would make the whole thing more flexible for stuff like
% functions that receive or return more complex values than doubles
% (Matlab is special anyway in the way that a function can have multiple return values)

% Instead of a function we can also test the output of a script in a similar manner

function test()
    % clc; % maybe clc is annyoing for the students
    print_header();

    test_function(@() findRootByBisection(@(x) x, -1, 1), 0)
    test_function(@() findRootByBisection(@(x) x, -1, 1), 1)
    test_function(@() findRootByBisection(@(x) x, 1, 2), "error")
    test_function(@() findRootByBisection(@(x) x, 1, 2), 0)
    test_function(@() infinite_loop(), 0);
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

function test_function(f, expected, rel_tol, abs_tol)
    % Executes function and prints result to terminal
    arguments
        f (1, 1) function_handle
        expected (1, 1) {string, double}
        rel_tol (1, 1) double = 1e-09
        abs_tol (1, 1) double = 0.0
    end

    % Values of result:
    PASSED = 0; % function returned & correct result
    FAILED = 1; % function returned & false result
    ERROR = 2; % function raised an error
    TIMEOUT = 3; % function did not return on time

    expects_error = isstring(expected) && expected == "error";

    % values of status and result are shared
    % PASSED and FINISHED are named differently tho
    % I wish enums would not require an extra file :(
    FINISHED = 0;
    [answer, status] = run_function(f);

    switch status
        case TIMEOUT
            result = TIMEOUT;
        case ERROR
            if expects_error
                result = PASSED;
            else
                result = ERROR;
            end

        case FINISHED
            if isclose(answer, expected, rel_tol, abs_tol)
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
    answer = string(answer);
    expected = string(expected);
    fprintf("%-50s %-12s %-12s", func, answer, expected);

    fprintf("\n");

end

function [answer, status] = run_function(f)
    % answer is return value of function
    % status is one of the following {FINISHED, ERROR, TIMEOUT}
    % if status = {ERROR, TIMEOUT} then answer is {"error", "timeout"} respectively
    FINISHED = 0;
    ERROR = 2;
    TIMEOUT = 3;
    % time to wait [s] for future to finish
    timeout_time = 0.5;

    try
        fut = parfeval(backgroundPool, f, 1);
        ok = fut.wait('finished', timeout_time);

        if ok
            answer = fetchOutputs(fut);
            status = FINISHED;
        else
            cancel(fut);
            answer = "timeout";
            status = TIMEOUT;
        end

    catch
        answer = "error";
        status = ERROR;
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
