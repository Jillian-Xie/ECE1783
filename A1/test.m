% test for getBestMV motionEstimate
clc; clear; close all;

% refFrame=[9 10 1 2
%           13 14 5 6
%           11 12 3 4
%           15 16 7 8];
% currentFrame=[1 2 3 4
%               5 6 7 8
%               9 10 11 12
%               13 14 15 16];
% 
% widthBlockIndex = 1;
% heightBlockIndex = 1;
% r = 2;
% blockSize = 2;
% n = 1;
% QP = 0;
% 
% % [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = motionEstimate(refFrame,currentFrame,blockSize,r,n,QP);
% 
% 
% 
% [modes, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = intraPrediction(currentFrame, blockSize, QP)

% block = [-31 9 8 4
%          -4 1 4 0
%          -3 2 4 0
%          4 0 -4 0];
% disp(scanBlock(block, 4));
% 
% array = [-31     9    -4     8     1    -3     4     4     2     4     0     4     0     0    -4     0];
% disp(RLE(array));
% 
% reverseArray = [-10   -31     9    -4     8     1    -3     4     4     2     4     1    -1     4     2    -1    -4     0];
% disp(reverseRLE(reverseArray, 4));
% 
% array = [1 0 0 0 0 0 0 0  0];
% disp(RLE(array));
% 
% reverseArray = [-1 1 0];
% disp(reverseRLE(reverseArray, 3));

% MVCell = {[1,2], [-1,2]};
% modes = [0, 1];
% 
% [diffMV, diffModes] = differentialEncoding(MVCell, modes)

y=[1 2 3 4
   2 3 4 5
   3 4 5 6
   4 5 6 7];
x=[1 1 1 1
   2 2 2 2
   3 3 3 3
   4 4 4 4];

plot(x,y)
