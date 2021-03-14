clear all; close all; clc;

rolloff = 0.25; % Filter rolloff
span = 8;       % Filter span
sps = 10;        % Samples per symbol
M = 4;          % Size of the signal constellation
k = log2(M);    % Number of bits per symbol

rrcFilter = rcosdesign(rolloff,span,sps);

data = randi([0 M-1],10000,1);

% Modulate
modData = qammod(data,M);

% Transmit
txSig = upfirdn(modData,rrcFilter,sps);

a = 1;
x_xmit = frft(txSig,a);

% Channel
EbNo = 8;
snr = EbNo + 10*log10(k) - 10*log10(sps);
y_ch = awgn(x_xmit,snr,'measured');

y_rcv = frft(y_ch, -a);

% Receiver
rxFilt = upfirdn(y_rcv,rrcFilter,1,sps);
rxFilt = rxFilt(span+1:end-span);

demodData = qamdemod(rxFilt, M);

mean(data == demodData)

% Plot
% hScatter = scatterplot(sqrt(sps)* ...
%     rxSig(1:sps*5000), ...
%     sps,0);
% hold on
% scatterplot(rxFilt(1:5000),1,0,'rx',hScatter)
% title('Received Signal, Before and After Filtering')
% legend('Before Filtering','After Filtering')
% axis([-3 3 -3 3]) % Set axis ranges
% hold off