function [mhat] = find_ML_path(node,k)
%Function:  Computes the ML estimate by traversing the Trellis Map, looking
%           for the survivors.

%node - nodes corresponding to the trellis map, contains survivors and
%       state transition
%k    - length of message that we are seeking.

%Initialize survivor and cost list.
p_survivor = zeros(1,length(node)+1);
cost       = zeros(1,length(node)+1);

%Initialize branch output, 1 = top branch taken, 0 = lower branch
branch     = ones(1,length(node));

%Initialize Survivor Trackback
branch(end)       = 0;
p_survivor(end)   = 1;
cost(end)         = node{length(node)}{1}.cost;
p_survivor(end-1) = node{length(node)}{1}.surv;
cost(end-1)       = node{length(node)}{1}.cost;

%Traverse Backwards -- look for surviving branches
for n=length(node)-1:-1:1
    p_survivor(n) = node{n}{p_survivor(n+1)}.surv;
    cost(n) = node{n}{p_survivor(n+1)}.cost;
    
    %If we take the lower branch, assign a 0.  Otherwise top branch is 
    %assigned a 0.
    if(node{n}{p_survivor(n+1)}.f{1} == p_survivor(n+2))
        branch(n) = 0;
    end
end

%The code word is only the first kth bits.  The last length(branch)-k bits
%are by defination, 0.
mhat = branch(1:k);
    