clear all; close all; clc;

%% Parameters
rng(42); % Set the random seed 

% Modulation
M = 16;      % 16 symbols
k = log2(M); % bits per symbol

% OFDM
numSC = 64;           % Number of OFDM subcarriers
cpLen = 16;            % OFDM cyclic prefix length

% Rician Channel
delayVector = (0:5:15)*1e-6; % Discrete delays of four-path channel (s)
gainVector  = [0 -3 -6 -9];  % Average path gains (dB)

% AWGN channel
awgnSNR = 15; % 15 dB

%% System objects
ofdmMod = comm.OFDMModulator('FFTLength', numSC, ...
                             'CyclicPrefixLength',cpLen, ...
                             'PilotInputPort', false, ...
                             'Windowing', true, 'WindowLength', 16);

ofdmDemod = comm.OFDMDemodulator('FFTLength',numSC,'CyclicPrefixLength',cpLen, ...
                                 'PilotOutputPort', false);                         
                         
ricianChan = comm.RicianChannel('SampleRate', 20e3, ...
                                'PathDelays',delayVector, ...
                                'AveragePathGains',gainVector, ...
                                'KFactor', 3, ...
                                'MaximumDopplerShift', 0, ...
                                'RandomStream','mt19937ar with seed', ...
                                'Seed', 42);
refConst = qammod(0:M-1, M);
constDiag = comm.ConstellationDiagram( ...
    'Name','Received Signal After Rician Fading', ...
    'XLimits',[-5, 5],'YLimits',[-5 5], ...
    'ReferenceConstellation',refConst);    

constDiag2 = comm.ConstellationDiagram( ...
    'Name','Received Signal After Rician Fading', ...
    'XLimits',[-5, 5],'YLimits',[-5 5], ...
    'ReferenceConstellation',refConst);  
                        
carrierSync = comm.CarrierSynchronizer( ...
    'DampingFactor',0.4,'NormalizedLoopBandwidth',0.001, ...
    'SamplesPerSymbol', 1,'Modulation','QAM');    

dataMod = @(d) qammod(d, M);
dataDemod = @(d) qamdemod(d, M);

channel = @(sig, snr) awgn( ricianChan(sig), snr, 'measured' );

%% Train synchronizer
for i = 1:100
syms = get_random_symbols(80, M, dataMod);
syms_ch = channel(syms, 15);

syms_carrier = carrierSync(syms_ch);
end
display("Done");

%% Derived parameters

% OFDM
ofdmDims = info(ofdmMod);
numDC = ofdmDims.DataInputSize(1);
% numPilot = ofdmDims.PilotInputSize(1);
frameSize = [k*numDC 1];

%% Main Loop

dataBin = randi([0,1],frameSize);         % Generate binary data
txData = bi2de(reshape(dataBin, [], k));  % Reshape and convert to decimal

% Transmitter
txSym = dataMod(txData);  % Symbol modulation
txSig = ofdmMod(txSym);   % Apply OFDM modulation

% Channel effects
fadedSig = ricianChan(txSig);                   % Rician Channel
awgnSig = awgn(fadedSig, awgnSNR, 'measured');  % AWGN Channel
rxSig = awgnSig;

% Receiver
% TODO: Symbol synchronization + phase compensation
rxCarrier = step(carrierSync, rxSig);
rxSync = rxCarrier;

rxSym = ofdmDemod(rxSync);
rxData = dataDemod(rxSym);


%% Utility
function syms = get_random_symbols(N, M, fsym)
    data = randi([0, M-1], N, 1);
    syms = fsym(data);
end