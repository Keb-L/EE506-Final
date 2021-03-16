clear all; close all; clc;

%% Parameters
rng(42); % Set the random seed 

N = 200; % train with 200 frames

% Modulation
M = 16;      % 16 symbols
k = log2(M); % bits per symbol

% OFDM
numSC = 64;           % Number of OFDM subcarriers
cpLen = 16;            % OFDM cyclic prefix length

% Rician Channel
Fs = 20e3;
delayVector = 0; % Discrete delays of four-path channel (s)
gainVector  = 0;  % Average path gains (dB)
ricianK = 3;        

% AWGN channel
awgnSNR = 15; % dB

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
                         
ricianChan = comm.RicianChannel('SampleRate', Fs, ...
                                'KFactor', ricianK, ...
                                'RandomStream','mt19937ar with seed', ...
                                'PathDelays',delayVector, ...
                                'AveragePathGains',gainVector, ...
                                'Seed', 42);

carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol', 1,'Modulation','QAM');    

%% Derived parameters

% OFDM
ofdmDims = info(ofdmMod);
numDC = ofdmDims.DataInputSize(1);
% numPilot = ofdmDims.PilotInputSize(1);
frameSize = [numDC 1];

%% Train synchronizer
preamble = (1+barker())/2;  % Length 13, unipolar
txData = zeros(frameSize(1)*N, frameSize(2));
for i = 1 : N
    payload = randi([0 M-1],frameSize-[barker.Length, 0]);
    txData((i-1)*frameSize(1) + (1:frameSize(1))) = [preamble; payload];
end

% Modulate
txSym = qammod(txData, M);  % Symbol modulation

% compute OFDM on each frame
for i = 1:N          
    iData = 1 + (i-1)*53:i*53;
    iOFDM = 1 + (i-1)*80:i*80;
    txSig(iOFDM, 1) = ofdmMod(txSym(iData));   % Apply OFDM modulation
end

% Channel effects
fadedSig = ricianChan(txSig);                   % Rician Channel
awgnSig = awgn(fadedSig, awgnSNR, 'measured');  % AWGN Channel
rxSig = awgnSig;

% Demodulate every frame
for i = 1:N          
iData = 1 + (i-1)*53:i*53;
iOFDM = 1 + (i-1)*80:i*80;
rxDemod(iData, 1) = ofdmDemod(rxSig(iOFDM));   % Apply OFDM modulation
end

% Train carrier synchronizer
rxSync = carrierSync(rxDemod);

scatterplot(rxDemod(end-numDC*10+1:end));
title('Before phase correction 1');

scatterplot(rxSync(end-numDC*10+1:end));
title('After phase correction 1');

phOffset = barker_phase_correction(txSym, rxDemod, barker);

%% Main Loop
payload = randi([0,M-1],frameSize-[barker.Length, 0]);         % Generate binary data
preamble = (1+barker())/2;  % Length 13, unipolar
txData = [preamble; payload];

% Transmitter
txSym = qammod(txData, M);  % Symbol modulation
txSig = ofdmMod(txSym);   % Apply OFDM modulation

% Channel effects
fadedSig = ricianChan(txSig);                   % Rician Channel
awgnSig = awgn(fadedSig, awgnSNR, 'measured');  % AWGN Channel
rxSig = awgnSig;

% Receiver
rxDemod = ofdmDemod(rxSig);

scatterplot(rxDemod);
title('Before phase correction');

rxNoSync = qamdemod(rxDemod, M);
[nosyncDataTtlErr,nosyncDataBER] = biterr(txData,rxNoSync);
fprintf("(Pre-carrier sync) Total bit errors: %d, bit error rate %f\n", nosyncDataTtlErr, nosyncDataBER);

% Phase compensation
rxSync = carrierSync(rxDemod);

scatterplot(rxSync);
title('Phase corrected');

rxData = qamdemod(rxSync, M);

[syncDataTtlErr,syncDataBER] = biterr(txData,rxData);
fprintf("(Carrier Sync) Total bit errors: %d, bit error rate %f\n", syncDataTtlErr, syncDataBER);

%%
% % Correct angle
phOffset = barker_phase_correction(txSym, rxSync, barker);

% Apply phase offset
resPhzSig = exp(1i*phOffset) * rxSync;
% Demodulate
resPhzData = qamdemod(resPhzSig,M);
% Compute bit errors
[resPhzTtlErr, resPhzBER] = biterr(txData,resPhzData);
fprintf("(Barker Phase correction) Total bit errors: %d, bit error rate %f\n", resPhzTtlErr, resPhzBER);

