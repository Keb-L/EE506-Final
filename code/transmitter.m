% "Waveform design for communicating radar systems using Fractional Fourier Transform" Simulation
% Kelvin Lin, Ali Alansari
% EE 506 Winter 2021

clear all; close all; clc;

% Parameters
% num_carrier = 1;
% num_frame = 10;
% frame_size = 16;
num_pilot = 4;

M = 16;           % QPSK/4QAM
k = log2(M); % bits/symbol
num_chirps = 9; % C - number of subcarrier chirps

% RRC filter parameters
rolloff = 0.25; % Filter rolloff
span = 6;       % Filter span
sps = 4;        % Samples per symbol

num_guard = nSamp*span/2; % G - guard bits

% Random bitstream generator
x = randi([0, 1], k*(num_chirps-1), 1);

%% Serial/Parallel
x_sp = reshape(x, num_chirps-1, k);

%% Guard Adder
% guard_bits = zeros(num_chirps-1, num_guard);
% x_guard = [x_sp, guard_bits];

%% Channel Coding
% constlen=7;
% codegen = [171 133];    % Polynomial
% trellis = poly2trellis(constlen, codegen);
% 
% for idx = 1:size(x_guard, 1)
%     x_coded(idx, :) = convenc(x_guard(idx, :), trellis);
% end

%% Interleaver
x_intrlvd = matintrlv(x_sp, 4,2); % Interleave.


%% Digital Modulator
x_dec = binmat2dec(x_intrlvd, k);
x_mod = qammod(x_dec, M);

%% RRC Filter
rrcFilter = rcosdesign(rolloff,span,sps);
x_rrc = upfirdn(x_mod,rrcFilter,sps);

%% OFDM (frft a = 1)
x_xmit = frft(x_rrc, a);