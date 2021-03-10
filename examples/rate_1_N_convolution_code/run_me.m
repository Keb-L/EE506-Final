% Main code for ECE6606 project, Spring 2009, Georgia Tech
% Convolution Code by:  Romeil Sandhu

%Initialize Simulation Parameters
L = 1e2;              % message length
R = 1/3;              % code rate
dbs = -1:10;          % SNR per bit, in dB
trials = 1e3;         % number of trials to perform
%------------

%Define Impulse response for the n generators for a 1/n code - here n=3
g{1} = [1 0 1 1 0 0];                % Impulse Responses _ 1
g{2} = [1 1 0 1 0 0];                % Impulse Responses _ 2
g{3} = [1 1 1 1 0 0];                % Impluse Responses _ 3
n = length(g);                       % Convolution Code (1/n) parameter
memory_els = 3;
%---

%Initialize and compute Shannon Limit/Uncoded Efficiency
errs   = 0*dbs;
EbN0 = 10.^(dbs/10);
sigs = 1./sqrt(2*R*EbN0);
ber0 = logspace(-6,-2.1,81);
ber1 = logspace(-6,-0.99,81);
db0  = 10*log10((2.^(2*R*(1+log2((ber0.^ber0).*(1-ber0).^(1-ber0))))-1)/(2*R));
db1  = 20*log10(erfinv(1-2*ber1));
for trial = 1:trials,

    m = round(rand(1,L));            % message vector
    
    %--------- ENCODER: 1/3 Convolution Encoder -------%
    c = encode_1_3(m,g,n);
    %--------------------------------------------------%

    %verify code rate!
    if trial==1,disp(['Measured R = ',num2str(length(m)/length(c))]);end;
    noise = randn(1,length(c));
    for i=1:length(dbs),
        r = 2*c - 1 + sigs(i)*noise;
        
	%--- DECODER:  Convolution Decoder via Trellis Map, ML estimate ---%
    %--- flag = 1 ==> Hard Decoding
    %--- flag = 0 ==> Soft Decoding
    [mhat,node] = decode_1_3(r,n,memory_els,L,0);
	%----------------------------------------------%
	errs(i) = errs(i) + sum(mhat~= m); 
    end
    
    %Plot Simulated Result
    ber = errs/(L*trial);
    [trial, errs]
    semilogy(dbs, ber,'o-', db0, ber0,':', db1, ber1,':');
    hold off;
    xlabel('SNR per bit, E_b / N_0 (dB)');
    ylabel('Bit-Error Rate');
    axis([-1 10 1e-6 1])
    title(['After ',num2str(trial),' trials (',num2str(L*trial),' msg bits)']);
    grid on;
    drawnow;

end;
