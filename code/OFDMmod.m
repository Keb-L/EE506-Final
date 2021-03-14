clear all; close all; clc;
% https://www.mathworks.com/help/comm/gs/qpsk-and-ofdm-with-matlab-system-objects-1.html

M = 4;                 % Modulation alphabet
k = log2(M);           % Bits/symbol
numSC = 64;           % Number of OFDM subcarriers
cpLen = 16;            % OFDM cyclic prefix length
maxBitErrors = 100;    % Maximum number of bit errors
maxNumBits = 1e7;      % Maximum number of bits transmitted

% Modulators
qpskMod = comm.QPSKModulator('BitInput',true);
qpskDemod = comm.QPSKDemodulator('BitOutput',true);

% Create OFDM system objects
ofdmMod = comm.OFDMModulator('FFTLength',numSC,'CyclicPrefixLength',cpLen, 'Windowing', true, 'WindowLength', 16);
ofdmDemod = comm.OFDMDemodulator('FFTLength',numSC,'CyclicPrefixLength',cpLen);

channel = comm.AWGNChannel('NoiseMethod','Variance', ...
    'VarianceSource','Input port');

errorRate = comm.ErrorRate('ResetInputPort',true);

ofdmDims = info(ofdmMod)
numDC = ofdmDims.DataInputSize(1)

frameSize = [k*numDC 1];

EbNoVec = (0:10)';
snrVec = EbNoVec + 10*log10(k) + 10*log10(numDC/numSC);

berVec = zeros(length(EbNoVec),3);
errorStats = zeros(1,3);

snr = snrVec(1);

dataIn = randi([0,1],frameSize);              % Generate binary data
qpskTx = qpskMod(dataIn);                     % Apply QPSK modulation
txSig = ofdmMod(qpskTx);                      % Apply OFDM modulation
powerDB = 10*log10(var(txSig));               % Calculate Tx signal power
noiseVar = 10.^(0.1*(powerDB-snr));           % Calculate the noise variance
rxSig = channel(txSig,noiseVar);              % Pass the signal through a noisy channel
qpskRx = ofdmDemod(rxSig);                    % Apply OFDM demodulation
dataOut = qpskDemod(qpskRx);                  % Apply QPSK demodulation
errorStats = errorRate(dataIn,dataOut,0);     % Collect error statistics
