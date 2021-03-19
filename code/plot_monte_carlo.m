clear all; close all; clc;

load('MonteCarloSim_Final_Barker2.mat');

lgd_arr = [];

figure(); 
% semilogy(EbN0, nBERMat); hold on;
% lgd_arr = [lgd_arr compose('Rician K=%.2f', ricianK)];

semilogy(EbN0, nBERMatB, '-.'); hold on;
lgd_arr = [lgd_arr compose('Rician K=%.2f', ricianK)];

semilogy(0:30, berawgn(0:30, 'qam', M), 'k-.');
lgd_arr = [lgd_arr {'Ideal AWGN'}];

% for k = ricianK
%     semilogy(0:30, berfading(0:30, 'qam', M, 1, k), '--');
% end
% lgd_arr = [lgd_arr compose('Ideal Rician K=%d', ricianK)];

legend(lgd_arr, 'Location', 'southwest');

grid on;
ylim([1e-6, 1]);
ylabel('Bit Error Rate');
xlabel('Eb/N0 (dB)');
% title(sprintf('OFDM over Rician Fading Channel (Phase uncorrected)'));
title(sprintf('OFDM over Rician Fading Channel (Phase corrected)\n Barker = %d', 2));