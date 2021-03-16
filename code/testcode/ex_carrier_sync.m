clear all; close all; clc;

%% Parameters
M = 16; % Modulation order
rng(42); % For repeatable results
barker = comm.BarkerCode(...
    'Length',13,'SamplesPerFrame',13);  % For preamble
msgLen = 1e4;
numFrames = 10;
frameLen = msgLen/numFrames;

%% Create data stream
preamble = (1+barker())/2;  % Length 13, unipolar
data = zeros(msgLen,1);
for idx = 1 : numFrames
    payload = randi([0 M-1],frameLen-barker.Length,1);
    data((idx-1)*frameLen + (1:frameLen)) = [preamble; payload];
end

qamSig = qammod(data, M);

%% Channel
delayVector = 0;%(0:5:15)*1e-6; % Discrete delays of four-path channel (s)
gainVector  = 0;%[0 -3 -6 -9]; % Average path gains (dB)
Fs = 20e3;

ricianChan = comm.RicianChannel('SampleRate', Fs, ...
                                'KFactor', 30, ...
                                'RandomStream','mt19937ar with seed', ...
                                'PathDelays',delayVector, ...
                                'AveragePathGains',gainVector, ...
                                'Seed', 42);
                            
fadedSig = ricianChan(qamSig);           % Apply channel effects
awgnSig  = awgn(fadedSig,50,'measured');     % Add Gaussian noise

rxSig = awgnSig;

scatterplot(rxSig);

%% Receiver
carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol',1,'Modulation','QAM');

syncSignal = carrierSync(rxSig);

axislimits = [-6 6];
constDiag = comm.ConstellationDiagram( ...
'XLimits', axislimits,'YLimits', axislimits, ...
'ReferenceConstellation', qammod(0:M-1,M), ...
'ChannelNames',{'Before convergence','After convergence'},'ShowLegend',true);

constDiag([syncSignal(1:1000) syncSignal(9001:10000)]);

%
syncData = qamdemod(syncSignal,M);

[syncDataTtlErr,syncDataBER] = biterr(data(6000:end),syncData(6000:end))
% scatterplot(syncSignal);

%% Barker phase ambiguity
idx = 9000 + (1:barker.Length);
phOffset = angle(qamSig(idx) .* conj(syncSignal(idx)));
phOffset = round((2/pi) * phOffset); % -1, 0, 1, +/-2
phOffset(phOffset==-2) = 2; % Prep for mean operation
phOffset = mean((pi/2) * phOffset); % -pi/2, 0, pi/2, or pi
disp(['Estimated mean phase offset = ',num2str(phOffset*180/pi),' degrees'])

resPhzSig = exp(1i*phOffset) * syncSignal;

resPhzData = qamdemod(resPhzSig,M);
[resPhzTtlErr, resPhzBER] = biterr(data(6000:end),resPhzData(6000:end))