clc; clear; close all; 

% config info
yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 10;
width  = uint32(352);
height = uint32(288);
blockSize = 8;
r = 2;
QP = 0;
n = 3;

% encoder
ex3_encoder(yuvInputFileName, nFrame, width, height, blockSize, r, n);

% decoder
ex3_decoder(yuvInputFileName, nFrame, width, height, blockSize)