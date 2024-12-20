function [root, iterations] = findRootByBisection(func, left, right)

assert(sign(func(left)) ~= sign(func(right)), "function should have different signs at left and right");

epsilon = 0.001;
iterations = 0;

while ~(min(abs(func(left)), abs(func(right))) < epsilon && (right - left) < epsilon)
    iterations = iterations + 1;
    middle = (left + right) / 2;

    if func(middle) == 0
        left = middle;
        right = middle;
        break;
    elseif sign(func(middle)) == sign(func(left))
        left = middle;
    else
        right = middle;
    end

end

if abs(func(left)) < abs(func(right))
    root = left;
else
    root = right;
end

end
