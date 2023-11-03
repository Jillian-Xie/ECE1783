clc; clear; close all; 

% config info
yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 10;
width  = uint32(352);
height = uint32(288);
blockSize = 8;
r = 2;
QP = 0;
I_Period = 1;

% encoder
tic
ex4_encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period)
toc

load('QTCCoeffs.mat', 'QTCCoeffs');
load('MDiffs.mat', 'MDiffs');

% decoder
tic
ex4_decoder(nFrame, width, height, blockSize, QP, I_Period, QTCCoeffs, MDiffs);
toc
