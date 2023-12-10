clc; clear; close all;

% config info
yuvInputFileName = 'CIF.yuv';
nFrame = 3;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QPs = [0 1 2 3 4 5 6 7 8 9 10 11];
QP = 4;
I_Period = 21;

nRefFrames = 1;
VBSEnable = true;
FMEEnable = true;
FastME = true;

RCFlag = 0;
targetBR = 1140480; % bps
frameRate = 30;

visualizeVBS = VBSEnable && true;
visualizeRGB = true;
visualizeMM = true;
visualizeNRF= true;

% Parallel mode enabled
parallelMode = 3;

% Encoder execution with Parallel Mode
tic
reconstructedY = encoder_parallelMode3(yuvInputFileName, nFrame, width, height, ...
    blockSize, r, QP, I_Period, VBSEnable, FMEEnable, FastME);
toc

% Load encoder output
load('QTCCoeffs.mat', 'QTCCoeffs');
load('MDiffs.mat', 'MDiffs');
load('splits.mat', 'splits');
load('QPFrames.mat', 'QPFrames');

tic
decoder(nFrame, width, height, blockSize, VBSEnable, FMEEnable, ...
    QTCCoeffs, MDiffs, splits, QPFrames, visualizeVBS, visualizeRGB, visualizeMM, ...
    visualizeNRF, reconstructedY);
toc