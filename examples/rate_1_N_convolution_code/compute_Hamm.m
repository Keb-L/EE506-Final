function dist = compute_Hamm(o,r,block_st,n)
%Function:  Computes the Hamming Distance.
%o        - lth branch vector of the trellis map
%r        - total received vector
%block_st - branch currently on
%n        - length of vector block

rhat = r(block_st:block_st+n-1);  %Find r branch vector
dist = sum(o ~= rhat);            %Computes Hamming Distance