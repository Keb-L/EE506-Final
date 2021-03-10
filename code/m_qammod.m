function y = m_qammod(x, M)
% Only works for square QAMs (4, 16, 64, 256, ...)
% y : QAM modulated signal 
% x : input signal
% M : modulation order (# of points in constellation
assert( floor(log(M)/log(4)) == log(M)/log(4), sprintf("Unsupported value of M. (Got %d)", M));
assert( ~any(x >= M), "Invalid data. Found values that exceed symbol range.");

qammap = get_qammap(M); % MQAM mapping 0:M-1 to IQ value

y = zeros(numel(x), 1);
for i = 1:numel(x)
    y(i) = qammap(x(i)+1);
end
y = reshape(y, size(x));
end

function qammap = get_qammap(M)
k = log2(M); % number of bits in each constellation

bits = (0:sqrt(M)-1)';

% QAM coordinates
alphaRe = [-(2*sqrt(M)/2-1):2:-1 1:2:2*sqrt(M)/2-1]';
alphaIm = [-(2*sqrt(M)/2-1):2:-1 1:2:2*sqrt(M)/2-1]';

% Converts integer into graycode
bin2gray = @(x) bitxor(x, bitshift(x, -1));
gc = bin2gray(bits);

% Compute the integer lookup
prefix = repelem(gc, sqrt(M));
suffix = repmat(gc, sqrt(M), 1);

% Compute the QAM I/Q lookup
qamRe = repelem(alphaRe, sqrt(M));
qamIm = repmat(alphaIm, sqrt(M), 1);

vals = bin2dec([dec2bin(prefix) dec2bin(suffix)]);
% Generate the lookup table
qamtable = sortrows([vals, qamRe, qamIm], 1);

% Convert to I/Q values
qammap = qamtable(:, 2) + j*qamtable(:, 3);
end