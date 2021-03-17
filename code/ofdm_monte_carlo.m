clear all; close all; clc;

%%
rng(42); % Set the random seed, reproducible results

%--------------------------------------------------------------------------
% Monte Carlo Simulation parameters
N = 1e4; % Frames per simulation
batch_size = 1e3; % Do batchs of batch_size at a time
batch_iter = N / batch_size;

ricianK = [1, 3, 5, 10, 30]; % ratio of signal power (dominant component) to scattered power dB
awgnSNR = [0:5:30]; % ratio of signal power to noise power dB
%--------------------------------------------------------------------------

% Modulation
M = 4;      % 16 symbols - 16QAM
k = log2(M); % bits per symbol

% OFDM
numSC = 64;     % Number of OFDM subcarriers
cpLen = 16;     % OFDM cyclic prefix length

% Rician Channel
Fs = 20e3;
delayVector = 0; %(0:5:15)*1e-6; % Discrete delays of four-path channel (s)
gainVector  = 0; %[0 -3 -6 -9]; % Average path gains (dB)     

% Preamble
barker = comm.BarkerCode(...
    'Length',13,'SamplesPerFrame',13);  % For preamble

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

for i = 1:numel(ricianK)
    ricianChan = hricianChan(ricianK(i));
    
    for j = 1:numel(awgnSNR)
        fprintf("Simulating %d frames @ K = %d dB and awgnSNR = %d dB...\n", N, ricianK(i), awgnSNR(j));
        % Output values
        frameErr = zeros(batch_iter, 1);
        frameBER = zeros(batch_iter, 1);
        
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
            clear payload; 
            
            % Symbol Modulation
            txSym = qammod(txData, M);  % Symbol modulation
  
            % OFDM modulation   
            txSig = zeros(ofdmDims.OutputSize(1), batch_size);
            for batch = 1:batch_size
                txSig(:, batch) = ofdmMod(txSym(:, batch));
            end
            
            % Apply channel effects
            rxSig = zeros(size(txSig));
            for batch = 1:batch_size
                [fadedSig, chanGains] = ricianChan(txSig(:, batch));         % Rician Channel
                awgnSig = awgn(fadedSig, awgnSNR(j), 'measured');  % AWGN Channel
                rxSig(:, batch) = awgnSig;
            end
                     
            % OFDM demodulation
            rxSym = zeros(ofdmDims.DataInputSize(1), 1);
            rxSymBarker = zeros(ofdmDims.DataInputSize(1), batch_size);
            for batch = 1:batch_size
                rxSym = ofdmDemod(rxSig(:, batch));
                
                % Phase/Power correction
                [dPh, dPwr] = barker_phase_correction(txSym(:, batch), rxSym, barker); % Barker Preamble correction
                rxSymBarker(:, batch) = mean(dPwr).*exp(1i*mean(dPh)).*rxSym; 
            end
            
            % Symbol Demodulation
            rxDataBarker = qamdemod(rxSymBarker, M);
            
            % Compute outputs
            [frameErr(f), frameBER(f)] = biterr(txData, rxDataBarker);
            
        end
        fprintf("]\n");
        iter_time = toc(iter_start);
        fprintf("Iteration took %f seconds, average time per batch %f seconds\n", iter_time, double(iter_time)/batch_iter);
        
        % Sum and average frame error -> BER
        TotalBits = N*numDC*k ; % Number of frames * number of symbols * bits per symbol
        nErrMat(i, j) = sum(frameErr);
        nBERMat(i, j) = nErrMat(i, j) / TotalBits;
        
        fprintf("Total Bit Errors: %d, Bit Error Rate %f...\n\n", nErrMat(i, j), nBERMat(i, j));
        
        % Create checkpoint
        save('MonteCarloSim.mat', 'ricianK', 'awgnSNR', ...              % Axis parameters
                                  'nErrMat', 'nBERMat', 'TotalBits', ... % Output values
                                  'M', 'N', 'numSC', 'cpLen', 'Fs', 'delayVector', 'gainVector'); % Other parameters
    end
end