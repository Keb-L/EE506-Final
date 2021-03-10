function matout = binmat2dec(mat, Nbits)
% mat: input binary matrix
% Nbits : number of bits per column

iters = size(mat, 2) / Nbits;
assert(floor(iters) == iters, sprintf("Could not divide input matrix evenly into groups of %d bits", Nbits));

matout = zeros(size(mat, 1), iters);
k = ((Nbits-1):-1:0)';      % Bit position
v = 2.^k;                   % Bit to decimal conversion

for i = 0:iters-1
   tmpmat = mat(:, i*Nbits+1:(i+1)*Nbits); % Slice "Nbits" column
   matout(:, i+1) = tmpmat*v;
end

end