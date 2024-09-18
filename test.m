% Alternatively we could not print "output" and "expected"
% This would make the whole thing more flexible for stuff like
% functions that receive or return more complex values than doubles

% Instead of a function we can also test the output of a script in a similar manner

function test()
    % clc; % maybe clc is annyoing for the students
    print_header();

    run_function(@() findRootByBisection(@(x) x, -1, 1), 0)
    run_function(@() findRootByBisection(@(x) x, -1, 1), 1)
    run_function(@() findRootByBisection(@(x) x, 1, 2), "error")
    run_function(@() findRootByBisection(@(x) x, 1, 2), 0)
end

function print_header()
    fprintf("         ");
    fprintf("%-50s %-12s %-12s", "input", "output", "expected");
    fprintf("\n");
end

function run_function(f, expected, rel_tol, abs_tol)
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
    ERROR = 2; %  function raised an error

    % if expected=="error", return PASSED if error was raised, otherwise FAILED
    % we need to avoid ALL our errors in try-catch block -> do some extra checks
    expects_error = false;
    if isstring(expected) 
        if expected == "error"
            expects_error = true;
        else
            error('expected is a string but not "error"');
        end
    end

    try
        answer = f();

        if expects_error
            result = FAILED;
        elseif isclose(answer, expected, rel_tol, abs_tol)
            result = PASSED;
        else
            result = FAILED;
        end

    catch
        answer = "error";

        if expects_error
            result = PASSED;
        else
            result = ERROR;
        end

    end

    %% Print to output

    % 1 is stdout
    % 2 is stderr
    % We (ab)use the fact that Matlab prints stderr red in terminal.
    if result == PASSED
        fprintf(1, "[PASSED] ");
    elseif result == FAILED
        fprintf(2, "[FAILED] ");
    elseif result == ERROR
        fprintf(2, "[ERROR]  ");
    else
        error("invalid result");
    end

    func = func2str(f);
    % get rid of `@()` at start
    func = func(4:end);
    answer = string(answer);
    expected = string(expected);
    fprintf("%-50s %-12s %-12s", func, answer, expected);

    fprintf("\n");

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
