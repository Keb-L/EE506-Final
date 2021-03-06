function [mhat,node] = decode_1_3(r,n,mem,k,flag)
%Function:  This is the decoder for a generalized convolution encoder.
%This file is independent of the desired rate and memory elements.  It
%first produces a trellis map where we have assigned node states (previous
%and forward) as well as the cost functions associated with received vector
%and acceptable code words.  Note:  Only implements for our binary case.

%r    - codeword
%n    - output (1/n) convolution coder
%m    - number of memory elements
%k    - number of original message bits
%flag - Soft/Hard Decoding ==> 0/1.

%%%%%%%%%%%%%%%%%%%%%%%%%%%PSEUDO CODE%%%=%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1) Initialize next set of nodes, states, stages, etc.

%2) Traverse through nodes that have only been visited (i.e., no need to
%   check on nodes (2,3,4) of a 4 state Trellis Map at time = 1 since we
%   know that we should only visit node 1 given that we begin here.

%3) Given q = 2, we have two inputs = {0,1}.  Input each value and update
%   nodes accordingly
%   
%4) Compute acceptable output for each branch of the map, which is
%   formed from the function circuit_logic.  This changes
%   with each encoder.

%5) Compute distance between received vector and acceptable vector for each
%   of the branch at the ith stage.

%6) Update Nodes - a) Next State of the node (Could have 2 Possibilities) 
%                    b) Previous State of Node (Could have 2 Possibilities)
%                    c )Node has been visited?  
%                    d)Total Cost assigned to Node
%                    e) List/Determine Surviving Branch
%
%7) Form the decoded message by traversing backwards and finding the 
%   surviving Branches and Maximum Likelihood (ML) estimate.  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(STEP 1)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Develop Trellis Map for decoder.  Find # of stages and # of states.
stages = k+mem;
states = 2^mem;
block_st= 1;
%------

%If flag = 1 -> Hard Decoding.  We must first make "hard" decisions of the
%input received vector.
if(flag)
    ind_1 = r>0;
    ind_0 = r<=0;
    r(ind_1) = 1;
    r(ind_0) = -1;
end
%-----

%Initialize State or Memory/Input Elements
for i = 1:mem; c_S.m{i} = 0; end
c_S.st    = 1;
c_S.in    = 0;
%-----

%Initialize Trellis Map, which state we start with etc.
for l = 1:states
    node{1}{l}.p{1}   = NaN;
    node{1}{l}.p{2}   = NaN;
    node{1}{l}.f{1}   = NaN;
    node{1}{l}.f{2}   = NaN;
    node{1}{l}.cost   = -100000;
    node{1}{l}.visit  = 0;
    node{1}{l}.surv   = NaN;
end
node{1}{1}.visit = 1;
node{1}{1}.surv  = 1;
node{1}{1}.cost  = 0;
%-----

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(STEP 2)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:stages
    %Update block status, and initialize next set of nodes
    if(i~=1);block_st = block_st+n; end
    for l = 1:states
        node{i+1}{l}.p{1}   = NaN;
        node{i+1}{l}.p{2}   = NaN;
        node{i+1}{l}.f{1}   = NaN;
        node{i+1}{l}.f{2}   = NaN;
        node{i+1}{l}.cost   = -100000;
        node{i+1}{l}.visit  = 0;
        node{i+1}{l}.surv   = NaN;
    end
    
    %For each state or node, check if we need to do processing on.
    for l = 1:states
        if(node{i}{l}.visit)
            %If we do process this node, determine its current numerical
            %state
            c_S.st = l;
            val = l-1;
            for j = mem-1:-1:0
                if((val - 2^j)>=0)
                    c_S.m{j+1} = 1;
                    val = val-2^j;
                else
                    c_S.m{j+1} = 0;
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%(STEP 3-5)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %State Input = 0; (Binary, q=2)
            c_S.in   = 0;
            
            %Determine acceptable output from circuit logic
            [o,n_S] = circuit_logic(c_S,n,mem);
            
            %Soft or Hard Decoding (e.g., Hard => use Hamming Distance)
            if(flag)
                dist    = compute_Hamm(o,r,block_st,n);
            else
                dist    = compute_Lp(o,r,block_st,n);
            end
            
            %%%%%%%%%%%%%%%%%%%%(STEP 6)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Update node's status (e.g., node's status, total cost, is it a
            %possible survivor?)
            node{i}{c_S.st}.f{1}  = n_S.st;
            node{i}{c_S.st}.visit = 1;
           
            if(isnan(node{i+1}{n_S.st}.p{1}))
                node{i+1}{n_S.st}.p{1}  = c_S.st;
                node{i+1}{n_S.st}.visit = 1;
                node{i+1}{n_S.st}.cost  = node{i}{c_S.st}.cost+dist; 
                node{i+1}{n_S.st}.surv  = c_S.st;
            else
                node{i+1}{n_S.st}.p{2} = c_S.st;
                node{i+1}{n_S.st}.visit = 1;
                
                %Two Possible Survivors: Determine surviving branch
                if(node{i+1}{n_S.st}.cost<=node{i}{c_S.st}.cost+dist)
                    node{i+1}{n_S.st}.surv  =node{i+1}{n_S.st}.p{1};
                else
                    node{i+1}{n_S.st}.surv  = c_S.st;
                    node{i+1}{n_S.st}.cost  = node{i}{c_S.st}.cost+dist; 
                end       
            end
            
            %%%%%%%%%%%%%%%%%%%%(STEP 3-5)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %State Input = 1; (Binary, q=2)
            if(i<=k)
                %Only process input 1 for first k stages
                c_S.in   = 1; 
                
                 %Determine acceptable output from circuit logic
                [o,n_S] = circuit_logic(c_S,n,mem);
                
                %Update node's status (e.g., node's status, total cost, is it a
                %possible survivor?)
                if(flag)
                    dist    = compute_Hamm(o,r,block_st,n);
                else
                    dist    = compute_Lp(o,r,block_st,n);
                end;
                 
                %%%%%%%%%%%%%%%%%%%%(STEP 6)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                node{i}{c_S.st}.f{2}  = n_S.st;
                node{i}{c_S.st}.visit = 1;
                if(isnan(node{i+1}{n_S.st}.p{1}))
                    node{i+1}{n_S.st}.p{1} = c_S.st;
                    node{i+1}{n_S.st}.visit = 1;
                    node{i+1}{n_S.st}.cost  = node{i}{c_S.st}.cost+dist;
                    node{i+1}{n_S.st}.surv  = c_S.st;
                else
                    node{i+1}{n_S.st}.p{2} = c_S.st;
                    node{i+1}{n_S.st}.visit = 1;
                    
                    %Two Possible Survivors: Determine surviving branch
                    if(node{i+1}{n_S.st}.cost<=node{i}{c_S.st}.cost+dist)
                        node{i+1}{n_S.st}.surv  =node{i+1}{n_S.st}.p{1};
                    else
                        node{i+1}{n_S.st}.surv  = c_S.st;
                        node{i+1}{n_S.st}.cost  = node{i}{c_S.st}.cost+dist; 
                    end
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(STEP 7)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mhat = find_ML_path(node,k);
end