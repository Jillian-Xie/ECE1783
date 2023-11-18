clc; clear; close all; 

% config info
yuvInputFileName = 'synthetic.yuv';
nFrame = 10;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QP = 4;
I_Period = 10;

nRefFrames = 4;
VBSEnable = false;
FMEEnable = false;
FastME = false;

visualizeVBS = VBSEnable && true;

% encoder
tic
reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME);
toc

load('QTCCoeffs.mat', 'QTCCoeffs');
load('MDiffs.mat', 'MDiffs');
load('splits.mat', 'splits');

% decoder
tic
decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, reconstructedY);
toc
