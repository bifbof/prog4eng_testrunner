% Run tests for the function programmed in the exercise
%
% To call just run the following in a script or the command window:
% test_simulateBallDrop()

% This test-file is not like the others, it is hacked together. :)
% Date: 2024
% Author: Christof Leutenegger
function test_simulateBallDrop()
    print_header();

    test_function(@()simulateBallDrop(0), 1, 1);
    test_function(@()simulateBallDrop(1), 1, 1 + 1);
    test_function(@()simulateBallDrop(10), 1, 10 + 1);
    test_function(@()simulateBallDrop(100), 1, 100 + 1);
    test_function(@()simulateBallDrop(1000), 1, 1000 + 1);
    test_function(@()simulateBallDrop(10000), 1, 10000 + 1);
end

%% Global constants
function val = TIMEOUT_TRESH
    % timeout time for function in seconds
    % higher because we do many iterations
    val = 10.0;
end
function val = FMT_STR
    val = "%-30s %-14s %-8s";
end
function val = NUMITERS
    val = 1000;
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

function print_header()
    fprintf("          ");
    fprintf(FMT_STR, "input", "repetitions", "output/reason"); %#ok<CTPCT>
    fprintf("\n");
end

%% Functions to run test
function test_function(f, lower, upper, kwargs)
    % Test if function output lies between lower and upper and writes result to terminal.
    %
    % Parameters
    % ----------
    % f: function_handle
    %     Function to be tested against output.
    % lower: double
    %     Lower bound of output (inclusive).
    % higher: double
    %     Upper bound of output (inclusive).
    % kwargs.should_error: logical, default false
    %     Note if function should fail in this case.
    arguments
        f (1, 1) function_handle
        lower (1, 1) double
        upper (1, 1) double
        kwargs.should_error (1, 1) logical = false
    end
    % Values of result (only local to this function)
    % I wish enums would not require an extra file :(
    PASSED = 0; % function returned & correct result
    FAILED = 1; % function returned & false result
    ERROR = 2; % function raised an error
    TIMEOUT = 3; % function did not return on time

    answer = 0;
    all_answers = zeros(1, NUMITERS);
    wrong_answer = false;
    status = STATUS_FINISHED;
    % repeat function call until reached NUMITERS or error/timeout/wrong output
    % so last answer is the one we can output.
    for ii = 1:NUMITERS
        [answer, status] = run_function(f);
        if status == STATUS_ERROR || status == STATUS_TIMEOUT
            break;
        end
        % move test_equal from other test_xyz to this line instead (bit hacky :D)
        if ~isequal(size(answer), [1, 1]) || ~isequal(class(answer), 'double') ...
           || answer < lower || upper < answer || round(answer) ~= answer
            wrong_answer = true;
            break;
        else
            all_answers(ii) = answer;
        end
    end

    nondet = true;
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
            elseif wrong_answer
                result = FAILED;
            elseif lower < upper
                % do some additional check if we have non-deterministic outputs
                nondet = any(all_answers(1) ~= all_answers);
                if nondet
                    result = PASSED;
                else
                    result = FAILED;
                end
            else
                result = PASSED;
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

    % Only works as we don't expect an error while calling this function!
    % Else we would have to say we expected an error like in other tests.
    % But we don't have an expected output field in the output string for that.
    if result == PASSED
        answer = "-";
    elseif ~nondet
        answer = "output always same";
    end
    answer = stringify(answer);
    repetitions = stringify(NUMITERS);

    fprintf(FMT_STR, func, repetitions, answer);
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
