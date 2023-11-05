clc; clear; close all; 

% config info
yuvInputFileName = 'synthetic.yuv';
nFrame = 4;
width  = uint32(352);
height = uint32(288);
blockSize = 8;
r = 2;
QP = 0;
I_Period = 3;

nRefFrames = 2;
VBSEnable = false;
FMEEnable = false;
FastME = false;

% encoder
tic
encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME)
toc

load('QTCCoeffs.mat', 'QTCCoeffs');
load('MDiffs.mat', 'MDiffs');

% decoder
tic
decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs);
toc
