% "Waveform design for communicating radar systems using Fractional Fourier Transform" Simulation
% Kelvin Lin, Ali Alansari
% EE 506 Winter 2021

clear all; close all; clc;

% Parameters
num_carrier = 1;
num_frame = 10;
frame_size = 16;
Mmod = 4;           % QPSK/4QAM
num_pilot = 4;

N = log2(Mmod);
num_chirps = 9; % C - number of subcarrier chirps
num_guard = 0; % G - guard bits

% Random bitstream generator
x = randi([0, 1], 16, 1);

%% Serial/Parallel
x_sp = reshape(x, num_chirps-1, N);

%% Guard Adder
guard_bits = zeros(num_chirps-1, num_guard);
x_guard = [x_sp, guard_bits];

%% Interleaver
x_intrlvd = m_matintrlv(x_guard, 4,2); % Interleave.


%% Digital Modulator
x_dec = binmat2dec(x_intrlvd, N);
x_mod = m_qammod(x_dec, Mmod);


%% RRC Filter

%% FrFT

%% Pilot Generator


% x_deintrlvd = matdeintrlv(x_intrlvd, 4, 2);