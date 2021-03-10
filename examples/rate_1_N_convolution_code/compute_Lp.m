function dist = compute_Lp(o,r,block_st,n)
%Function:  Computes the Lp norm... approximate.
%o        - lth branch vector of the trellis map
%r        - total received vector
%block_st - branch currently on
%n        - length of vector block

p = 2;
rhat = r(block_st:block_st+n-1);   %Find r branch vector
dist = (sum(abs(o-rhat).^p));      %Compute Lp distance


