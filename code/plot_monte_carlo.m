clear all; close all; clc;

load('MonteCarloSim.mat');

lgd_arr = []

figure(); 
semilogy(EbN0, nBERMat); hold on;
lgd_arr = [lgd_arr compose('Rician K=%d dB', ricianKdB)];

semilogy(0:30, berawgn(0:30, 'qam', M), '--');
lgd_arr = [lgd_arr {'Ideal AWGN'}];

for k = ricianK
    semilogy(0:30, berfading(0:30, 'qam', M, 1, k), '--');
end
lgd_arr = [lgd_arr compose('Ideal Rician K=%d dB', ricianKdB)];

legend(lgd_arr);

grid on;
ylim([1e-6, 1]);
ylabel('Bit Error Rate');
xlabel('Eb/N0 (dB)');