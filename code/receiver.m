% "Waveform design for communicating radar systems using Fractional Fourier Transform" Simulation
% Kelvin Lin, Ali Alansari
% EE 506 Winter 2021
% Receiver


clear all; close all; clc;

% Parameters

% num_carrier = 1;
% num_frame = 10;
% frame_size = 16;
num_pilot = 4;
a = 0.4;

M = 16;           % QPSK/4QAM
k = log2(M); % bits/symbol
num_chirps = 9; % C - number of subcarrier chirps

% RRC filter parameters
rolloff = 0.25; % Filter rolloff
span = 6;       % Filter span
sps = 4;        % Samples per symbol

num_guard = sps*span/2; % G - guard bits

% Random bitstream generator
x = randi([0, 1], k*(num_chirps-1), 1);


% x should bbe signal coming in from transmitter
%% Serial to Parallel


x_sp = reshape(x, num_chirps-1, k);


%% Inverse FrFT

% perform ifrft on x_sp
% x_sp_ifrft = frft(x_sp,-a);

%% RRC Filter

rrcFilter = rcosdesign(rolloff,span,sps);
x_rrc = upfirdn(x_sp,rrcFilter,sps);

%% Digital Demodulator

x_dec = qamdemod(x_rrc,M);

%% Deinterleaver

x_deintrlvd = matdeintrlv(x_sp, 4,2); % Deinterleave.



%% Parallel to Serial --> Demodulated Data

x = reshape(x_deintrlvd, (num_xhirps-1)*k,1);






