clc; clear; close all; 

% config info
yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 3;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QP = 1;
I_Period = 10;
Lambda = getLambda(QP);

nRefFrames = 4;
VBSEnable = true;
FMEEnable = true;
FastME = false;

visualizeVBS = VBSEnable && false;
visualizeRGB = false;
visualizeMM = (~FMEEnable) && false;
visualizeNRF= false;

% encoder
tic
reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, Lambda);
toc

load('QTCCoeffs.mat', 'QTCCoeffs');
load('MDiffs.mat', 'MDiffs');
load('splits.mat', 'splits');

% decoder
tic
decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, visualizeRGB, visualizeMM, visualizeNRF, reconstructedY);
toc
