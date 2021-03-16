clear all; close all; clc;

%% Parameters
M = 16; % Modulation order
rng(42); % For repeatable results
barker = comm.BarkerCode(...
    'Length',13,'SamplesPerFrame',13);  % For preamble
N = 160;
msgLen = 53*N;
numFrames = N;
frameLen = msgLen/numFrames;

awgnSNR = 20;

%% Create data stream
preamble = (1+barker())/2;  % Length 13, unipolar
data = zeros(msgLen,1);
for idx = 1 : numFrames
    payload = randi([0 M-1],frameLen-barker.Length,1);
    data((idx-1)*frameLen + (1:frameLen)) = [preamble; payload];
end

qamSig = qammod(data, M);

numSC = 64;           % Number of OFDM subcarriers
cpLen = 16;            % OFDM cyclic prefix length
ofdmMod = comm.OFDMModulator('FFTLength', numSC, ...
                             'CyclicPrefixLength',cpLen, ...
                             'PilotInputPort', false, ...
                             'Windowing', true, 'WindowLength', 16);
for i = 1:N          
idx = 1 + (i-1)*53:i*53;
idx2 = 1 + (i-1)*80:i*80;
txSig(idx2, 1) = ofdmMod(qamSig(idx));   % Apply OFDM modulation
end

%% Channel
delayVector = 0;%(0:5:15)*1e-6; % Discrete delays of four-path channel (s)
gainVector  = 0;%[0 -3 -6 -9]; % Average path gains (dB)
Fs = 20e3;

ricianChan = comm.RicianChannel('SampleRate', Fs, ...
                                'KFactor', 3, ...
                                'RandomStream','mt19937ar with seed', ...
                                'PathDelays',delayVector, ...
                                'AveragePathGains',gainVector, ...
                                'Seed', 42);
                            
fadedSig = ricianChan(txSig);           % Apply channel effects
awgnSig  = awgn(fadedSig, awgnSNR,'measured');     % Add Gaussian noise

scatterplot(awgnSig);
title('AWGN signal');

%% Receiver
carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol',1,'Modulation','QAM');


rxSig = awgnSig;

ofdmDemod = comm.OFDMDemodulator('FFTLength',numSC,'CyclicPrefixLength',cpLen, ...
                                 'PilotOutputPort', false);  

for i = 1:N          
idx = 1 + (i-1)*53:i*53;
idx2 = 1 + (i-1)*80:i*80;
demodSig(idx, 1) = ofdmDemod(rxSig(idx2));   % Apply OFDM modulation
end

scatterplot(demodSig);
title('Demodulated signal');

syncSignal = carrierSync(demodSig);

scatterplot(syncSignal);
title('Synchronized signal');

%%
axislimits = [-6 6];
constDiag = comm.ConstellationDiagram( ...
'XLimits', axislimits,'YLimits', axislimits, ...
'ReferenceConstellation', qammod(0:M-1,M), ...
'ChannelNames',{'Before convergence','After convergence'},'ShowLegend',true);

constDiag([syncSignal(1:1000) syncSignal(7001:8000)]);

%
syncData = qamdemod(syncSignal,M);

[syncDataTtlErr,syncDataBER] = biterr(data(6000:end),syncData(6000:end))
% scatterplot(syncSignal);

%% Barker phase ambiguity
idx = 53*150+(1:barker.Length);
phOffset = angle(qamSig(idx) .* conj(syncSignal(idx)));
phOffset = round((2/pi) * phOffset); % -1, 0, 1, +/-2
phOffset(phOffset==-2) = 2; % Prep for mean operation
phOffset = mean((pi/2) * phOffset); % -pi/2, 0, pi/2, or pi
disp(['Estimated mean phase offset = ',num2str(phOffset*180/pi),' degrees'])

resPhzSig = exp(1i*phOffset) * syncSignal;

resPhzData = qamdemod(resPhzSig,M);
[resPhzTtlErr, resPhzBER] = biterr(data(6000:end),resPhzData(6000:end))