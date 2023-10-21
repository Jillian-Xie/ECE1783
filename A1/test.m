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

% [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = motionEstimate(refFrame,currentFrame,blockSize,r,n,QP);



[modeCell,I_blockCell, reconstructedY] = intraPrediction(currentFrame, blockSize);
