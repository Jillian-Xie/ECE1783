clc; clear; close all;

% config info
yuvInputFileName = 'CIF.yuv';
nFrame = 21;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QPs = [0 1 2 3 4 5 6 7 8 9 10 11];
QP = 5;
I_Period = 10;

nRefFrames = 1;
VBSEnable = true;
FMEEnable = true;
FastME = true;

RCFlag = 0;
targetBR = 1140480; % bps
frameRate = 30;
parallelMode = 2;
% parpool(2);

visualizeVBS = VBSEnable && false;
visualizeRGB = false;
visualizeMM = false;
visualizeNRF= false;
statistics = [];

if RCFlag >= 1
    % statistics{1} -> IFrame  statistics{2} -> PFrame
    % load statistics from file
    
    statistics = load('CIFStatistics.mat', 'CIFStatistics');
    statistics = statistics.CIFStatistics;

    % or get statistics
    % statistics = {};
    % 
    % statistics{1} = getStatistics(struct( ...
    %     'yuvInputFileName', yuvInputFileName, ...
    %     'nFrame', nFrame, ...
    %     'width', width, ...
    %     'height', height, ...
    %     'blockSize', blockSize, ...
    %     'r', r, ...
    %     'QPs', QPs, ...
    %     'I_Period', 1, ...
    %     'nRefFrames', nRefFrames, ...
    %     'VBSEnable', VBSEnable, ...
    %     'FMEEnable', FMEEnable, ...
    %     'FastME', FastME, ...
    %     'visualizeVBS', false, ...
    %     'visualizeRGB', false, ...
    %     'visualizeMM', false, ...
    %     'visualizeNRF', false ...        
    %     ));
    % 
    % statistics{2} = getStatistics(struct( ...
    %     'yuvInputFileName', yuvInputFileName, ...
    %     'nFrame', nFrame, ...
    %     'width', width, ...
    %     'height', height, ...
    %     'blockSize', blockSize, ...
    %     'r', r, ...
    %     'QPs', QPs, ...
    %     'I_Period', 21, ...
    %     'nRefFrames', nRefFrames, ...
    %     'VBSEnable', VBSEnable, ...
    %     'FMEEnable', FMEEnable, ...
    %     'FastME', FastME, ...
    %     'visualizeVBS', false, ...
    %     'visualizeRGB', false, ...
    %     'visualizeMM', false, ...
    %     'visualizeNRF', false ...
    %     ));
    % 
    % save('statistics');
end

% encoder
tic
reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, ...
    r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, ...
    targetBR, frameRate, QPs, statistics, parallelMode);
toc

load('QTCCoeffs.mat', 'QTCCoeffs');
load('MDiffs.mat', 'MDiffs');
load('splits.mat', 'splits');
load('QPFrames.mat', 'QPFrames');
% delete(gcp);

% decoder
tic
decoder(nFrame, width, height, blockSize, VBSEnable, FMEEnable, ...
    QTCCoeffs, MDiffs, splits, QPFrames, visualizeVBS, visualizeRGB, visualizeMM, ...
    visualizeNRF, reconstructedY);
toc
