% test for getBestMV motionEstimate
clc; clear; close all;

refFrame=[9 10 1 2
          13 14 5 6
          11 12 3 4
          15 16 7 8];
currentFrame=[1 2 3 4
              5 6 7 8
              9 10 11 12
              13 14 15 16];

widthBlockIndex = 1;
heightBlockIndex = 1;
r = 2;
blockSize = 2;
n = 1;
QP = 0;

% % [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = motionEstimate(refFrame,currentFrame,blockSize,r,n,QP);
% 
% 
% 
[modes, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = intraPrediction(currentFrame, blockSize, QP)

% block = [-31 9 8 4
%          -4 1 4 0
%          -3 2 4 0
%          4 0 -4 0];
% disp(scanBlock(block, 4));
% 
% array = [-31     9    -4     8     1    -3     4     4     2     4     0     4     0     0    -4     0];
% disp(reverseScannedBlock(array, 4));

a=linspace(1,64,64);
n=64;
b=randi([0, 1], [1, n]);
a=reshape(a,[8,8]);
b=reshape(b,[8,8]);