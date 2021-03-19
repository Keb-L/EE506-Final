% "Waveform design for communicating radar systems using Fractional Fourier Transform" Simulation
% Kelvin Lin, Ali Alansari
% EE 506 Winter 2021
% OFDM Main


% clear all; close all; clc;

%% Parameters
% rng(42); % Set the random seed 

N = 200; % train with 200 frames

% Modulation
M = 16;      % 16 symbols
k = log2(M); % bits per symbol
sps = 1;

% OFDM
numSC = 64;           % Number of OFDM subcarriers
cpLen = 16;            % OFDM cyclic prefix length

% Rician Channel
Fs = 15*10^6;  
delayVector = 0; %(0:5:15)*1e-6; % Discrete delays of four-path channel (s)
gainVector  = 0; %[0 -3 -6 -9]; % Average path gains (dB)
ricianK = 10;  

Fc = 2.4*10^9;  % Carrier frequency
c = 3*10^8;     % Speed of light (m/s)
v = (50*10^3)/3600;         % Velocity in m/s
fD = 0.001+(v/c)*Fc; %Hz

ricianKdB = 10*log10(ricianK);

% AWGN channel
EbN0 = 100; % dB
awgnSNR = EbN0+10*log10(k)-10*log10(sps);

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
                                'DirectPathDopplerShift', 0, ...
                                'MaximumDopplerShift', fD, ...
                                'PathGainsOutputPort', 1, ...
                                'Seed', 42);                 
% constDiag = comm.ConstellationDiagram(  'ReferenceConstellation', qammod(0:M-1,M), ...
%                                         'XLimits', [-6, 6], 'YLimits', [-6, 6], ...
%                                         'NumInputPorts', 8);
                            
% lineq = comm.LinearEqualizer('Algorithm', 'RLS', ...
%                              'Constellation', qammod(0:M-1, M));
% lineq.ReferenceTap = 1;

% carrierSync = comm.CarrierSynchronizer( ...
%     'SamplesPerSymbol', 1,'Modulation','QAM');    

%% Derived parameters

% OFDM
ofdmDims = info(ofdmMod);
numDC = ofdmDims.DataInputSize(1);
% numPilot = ofdmDims.PilotInputSize(1);
frameSize = [numDC 1];

%% Train synchronizer
preamble = (1+barker())/2;  % Length 13, unipolar
txData = zeros(numDC*N, 1);
for i = 1 : N
    payload = randi([0 M-1], numDC-barker.Length, 1);
    txData((i-1)*numDC + (1:numDC)) = [preamble; payload];
end

% Modulate
txSym = qammod(txData, M);  % Symbol modulation

% compute OFDM on each frame
txSig = zeros(N*ofdmDims.OutputSize(1), 1);
for i = 1:N          
    iData = 1 + (i-1)*53:i*53;
    iOFDM = 1 + (i-1)*80:i*80;
    txSig(iOFDM, 1) = ofdmMod(txSym(iData));   % Apply OFDM modulation
end

% Channel effects
[fadedSig, chanGains] = ricianChan(txSig);                   % Rician Channel

awgnSig = awgn(fadedSig, awgnSNR, 'measured');  % AWGN Channel
rxSig = awgnSig;

% Demodulate every frame
dPwrArr = zeros(N, 1); dPhArr = zeros(N, 1); % Arrays for phase and power offsets
rxSym = zeros(N*numDC, 1);
for i = 1:N          
iData = 1 + (i-1)*53:i*53;
iOFDM = 1 + (i-1)*80:i*80;
rxSym(iData, 1) = ofdmDemod(rxSig(iOFDM));   % Apply OFDM modulation

[dPhArr(i), dPwrArr(i)] = barker_phase_correction(txSym(iData), rxSym(iData), barker);
end
angle(chanGains(1))

rxSymCSI = 1./sum(abs(mean(chanGains, 1))).*exp(-1i*sum(angle(mean(chanGains, 1)))).*rxSym;     % Perfect CSI
rxSymBarker = mean(dPwrArr).*exp(1i*mean(dPhArr)).*rxSym; % Barker Preamble correction

% Demodulate symbols
rxData = qamdemod(rxSym, M);
rxDataCSI = qamdemod(rxSymCSI, M);
rxDataBarker = qamdemod(rxSymBarker, M);

% Outputs
scatterplot(txSym); title('QAM Modulation');
scatterplot(txSig); title('OFDM Modulation');
scatterplot(fadedSig); title('Rician Fading');
scatterplot(awgnSig); title('AWGN');
scatterplot(rxSig); title('OFDM Demodulation');
scatterplot(rxSym); title('Received symbols (before correction)');
% scatterplot(rxSymCSI); title('After phase correction (Perfect CSI)');
scatterplot(rxSymBarker); title('After preamble phase correction');
% 
[nerr,ber] = biterr(txData, rxData);
fprintf("(No correction) Bit Error Count: %d, Bit Error Rate (BER) %f\n", nerr, ber);
% 
[nerr,ber] = biterr(txData, rxDataBarker);
fprintf("(Preamble correction) Bit Error Count: %d, Bit Error Rate (BER) %f\n", nerr, ber);
% % Train carrier synchronizer
% % rxSync = carrierSync(rxDemod);
% % 
% % scatterplot(rxDemod(end-numDC*10+1:end));
% % title('Before phase correction 1');
% % 
% % scatterplot(rxSync(end-numDC*10+1:end));
% % title('After phase correction 1');
% 
% % phOffset = barker_phase_correction(txSym, rxDemod, barker);
% 
% %% Main Loop
% nErrors = zeros(N, 1);
% 
% payload = randi([0,M-1],frameSize-[barker.Length, 0]);         % Generate binary data
% preamble = (1+barker())/2;  % Length 13, unipolar
% txData = [preamble; payload];
% 
% % Transmitter
% txSym = qammod(txData, M);  % Symbol modulation
% txSig = ofdmMod(txSym);   % Apply OFDM modulation
% 
% % Channel effects
% [fadedSig, chanGains] = ricianChan(txSig);      % Rician Channel
% awgnSig = awgn(fadedSig, awgnSNR, 'measured');  % AWGN Channel
% rxSig = awgnSig;
% 
% % Receiver
% rxSym = ofdmDemod(rxSig);
% 
% [dPh, dPwr] = barker_phase_correction(txSym, rxSym, barker);
% % Correction
% rxSymCSI = 1./sum(abs(mean(chanGains, 1))).*exp(-1i*sum(angle(mean(chanGains, 1)))).*rxSym; % Perfect CSI
% rxSymBarker = dPwr.*exp(1i*dPh).*rxSym;
% % Phase compensation
% % rxSync = carrierSync(rxDemod);
% 
% rxData = qamdemod(rxSym, M);
% rxDataCSI = qamdemod(rxSymCSI, M);
% rxDataBarker = qamdemod(rxSymBarker, M);
% 
% 
% %% Outputs
% scatterplot(rxSym); title('Before phase correction');
% scatterplot(rxSymCSI); title('After phase correction (Perfect CSI)');
% scatterplot(rxSymBarker); title('After barker correction');
% 
% [nerr,ber] = biterr(txData, rxData);
% fprintf("(No correction) Bit Error Count: %d, Bit Error Rate (BER) %f\n", nerr, ber);
% 
% [nerr,ber] = biterr(txData, rxDataBarker);
% fprintf("(Preamble correction) Bit Error Count: %d, Bit Error Rate (BER) %f\n", nerr, ber);
