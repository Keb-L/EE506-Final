clear all; close all; clc;

%%
rng(42); % Set the random seed, reproducible results

%--------------------------------------------------------------------------
% Monte Carlo Simulation parameters
N = 1e5; % Frames per simulation
batch_size = 1e3; % Do batchs of batch_size at a time
batch_iter = N / batch_size;

ricianKdB = [0 3 10 14 17 20 30]; % ratio of signal power (dominant component) to scattered power (linear)
EbN0 = [0:1:10, 12:2:20 25 30]; % ratio of signal power to noise power dB
%--------------------------------------------------------------------------

% Modulation
M = 16;      % 16 symbols - 16QAM
k = log2(M); % bits per symbol
sps = 1;     % Samples per symbol

% OFDM
numSC = 64;     % Number of OFDM subcarriers
cpLen = 16;     % OFDM cyclic prefix length

% Rician Channel
Fs = 15*10^6;  % 15 MHz
delayVector = 0; %(0:5:15)*1e-6; % Discrete delays of four-path channel (s)
gainVector  = 0; %[0 -3 -6 -9]; % Average path gains (dB)    

Fc = 2.4*10^9;  % Carrier frequency
c = 3*10^8;     % Speed of light (m/s)
v = (50*10^3)/3600;         % Velocity in m/s
fD = 0.001+(v/c)*Fc; %Hz

ricianK = 10.^(ricianKdB/10);

% Preamble
barkerN = 2;
barker = comm.BarkerCode(...
    'Length',barkerN,'SamplesPerFrame',barkerN);  % For preamble

% ricianK = 10.^(ricianKdB/10);
awgnSNR = EbN0+10*log10(k)-10*log10(sps);


%% System objects
ofdmMod = comm.OFDMModulator('FFTLength', numSC, ...
                             'CyclicPrefixLength',cpLen, ...
                             'PilotInputPort', false, ...
                             'Windowing', true, 'WindowLength', 16);

ofdmDemod = comm.OFDMDemodulator('FFTLength',numSC,'CyclicPrefixLength',cpLen, ...
                                 'PilotOutputPort', false);                         
                         
hricianChan = @(K) comm.RicianChannel('SampleRate', Fs, ...
                                    'KFactor', K, ...
                                    'RandomStream','mt19937ar with seed', ...
                                    'PathDelays',delayVector, ...
                                    'AveragePathGains',gainVector, ...
                                    'MaximumDopplerShift', fD, ...
                                    'PathGainsOutputPort', 1, ...
                                    'Seed', 42);   
                            
%% Derived parameters

% OFDM
ofdmDims = info(ofdmMod);
numDC = ofdmDims.DataInputSize(1);
frameSize = [numDC 1];

preamble = (1+barker())/2;  % Length 13, unipolar

%% Monte Carlo Simulation
nErrMat = zeros(numel(ricianK), numel(awgnSNR));
nBERMat = zeros(numel(ricianK), numel(awgnSNR));
nErrMatB = zeros(numel(ricianK), numel(awgnSNR));
nBERMatB = zeros(numel(ricianK), numel(awgnSNR));

for i = 1:numel(ricianK)
    ricianChan = hricianChan(ricianK(i));
    
    for j = 1:numel(awgnSNR)
        fprintf("Simulating %d frames @ K = %d and Eb/N0 = %d dB...\n", N, ricianK(i), EbN0(j));
        % Output values
        frameErr = zeros(batch_iter, 1); frameErrB = zeros(batch_iter, 1);
        frameBER = zeros(batch_iter, 1); frameBERB = zeros(batch_iter, 1);
        
        iter_start = tic;
        
        % For each frame
        fprintf("\t[");
        for f = 1:(batch_iter)
            if (mod(f, batch_iter/10) == 0)
                fprintf(">");
            end
            
            % Generate frame data
            payload = randi([0 M-1], numDC-barker.Length, batch_size);
            txData = [repelem(preamble, 1, batch_size); payload];
%             txData = payload;
            clear payload; 
            
            % Symbol Modulation
            txSym = qammod(txData, M);  % Symbol modulation
  
            % OFDM modulation   
%             txSig = txSym;
            txSig = zeros(ofdmDims.OutputSize(1), batch_size);
            for batch = 1:batch_size
                txSig(:, batch) = ofdmMod(txSym(:, batch));
            end
%             
            % Apply channel effects
            rxSig = zeros(size(txSig));
            [fadedSig, chanGains] = ricianChan(txSig(:));  
            awgnSig = awgn(fadedSig, awgnSNR(j), 'measured');  % AWGN Channel 
            rxSig = reshape(awgnSig, ofdmDims.OutputSize(1), batch_size);
%             for batch = 1:batch_size
%                 [fadedSig, chanGains] = ricianChan(txSig(:, batch));         % Rician Channel
%                 awgnSig = awgn(fadedSig, awgnSNR(j), 'measured');  % AWGN Channel
%                 rxSig(:, batch) = awgnSig;
%             end
%             rxSig = awgn(txSig, awgnSNR(j), 'measured');  % AWGN Channel
                     
            % OFDM demodulation
%             rxSym = rxSig;
            rxSym = zeros(ofdmDims.DataInputSize(1), batch_size);
            rxSymBarker = zeros(ofdmDims.DataInputSize(1), batch_size);
            for batch = 1:batch_size
                rxSym(:, batch) = ofdmDemod(rxSig(:, batch));
                
                % Phase/Power correction
                [dPh, dPwr] = barker_phase_correction(txSym(:, batch), rxSym(:, batch), barker); % Barker Preamble correction
                rxSymBarker(:, batch) = mean(dPwr).*exp(1i*mean(dPh)).*rxSym(:, batch); 
            end
            
            % Symbol Demodulation
            rxData = qamdemod(rxSym, M);
            rxDataBarker = qamdemod(rxSymBarker, M);
            
            % Compute outputs
            [frameErr(f), frameBER(f)] = biterr(txData, rxData);
            [frameErrB(f), frameBERB(f)] = biterr(txData, rxDataBarker);
            
        end
        fprintf("]\n");
        iter_time = toc(iter_start);
        fprintf("Iteration took %f seconds, average time per batch %f seconds\n", iter_time, double(iter_time)/batch_iter);
        
        % Sum and average frame error -> BER
        TotalBits = N*numDC*k ; % Number of frames * number of symbols * bits per symbol
        nErrMat(i, j) = sum(frameErr);
        nErrMatB(i, j) = sum(frameErrB);
        nBERMat(i, j) = nErrMat(i, j) / TotalBits;
        nBERMatB(i, j) = nErrMatB(i, j) / TotalBits;
        
        fprintf("Total Bit Errors: %d, Bit Error Rate %f...\n\n", nErrMat(i, j), nBERMat(i, j));
        
        % Create checkpoint
        save('MonteCarloSim.mat', 'ricianK', 'ricianKdB', 'awgnSNR', 'EbN0', ...              % Axis parameters
                                  'nErrMat', 'nBERMat', 'nErrMatB', 'nBERMatB', 'TotalBits', ... % Output values
                                  'M', 'N', 'numSC', 'cpLen', 'Fs', 'delayVector', 'gainVector'); % Other parameters
    end
end