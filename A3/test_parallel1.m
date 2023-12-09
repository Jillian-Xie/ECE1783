clc; clear; close all;

% config info
yuvInputFileName = 'CIF.yuv';
nFrame = 21;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 16;
QPs = [0 1 2 3 4 5 6 7 8 9 10 11];
QP = 4;
I_Period = 21;

nRefFrames = 1;
VBSEnable = true;
FMEEnable = true;
FastME = true;

RCFlag = 0;
targetBR = 2400000; % bps
frameRate = 30;

visualizeVBS = VBSEnable && false;
visualizeRGB = false;
visualizeMM = false;
visualizeNRF= false;

% Parallel mode enabled
parallelMode = 1; % Enable Parallel Mode 1

% Load statistics if RCFlag >= 1
if RCFlag >= 1 
    statistics = load('CIFStatistics.mat', 'CIFStatistics');
    statistics = statistics.CIFStatistics;
else
    statistics = {};
end


% Core counts to test including non-parallel mode (0)
coreCounts = [0, 1, 2, 4];

for coreCount = coreCounts
    if coreCount == 0
        fprintf('Running without parallel processing\n');
        parallelMode = 0; % Disable Parallel Mode
    else
        fprintf('Running with %d core(s)\n', coreCount);
        parallelMode = 1; % Enable Parallel Mode 1
        if ~isempty(gcp('nocreate'))
            delete(gcp('nocreate'));
        end
        parpool(coreCount); % Create a parallel pool with specified number of cores
    end

    tic
    reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, ...
        r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, ...
        targetBR, frameRate, QPs, statistics, parallelMode);
    elapsedTime = toc;
    if coreCount == 0
        fprintf('Encoding time without parallel processing: %f seconds\n', elapsedTime);
    else
        fprintf('Encoding time with %d core(s): %f seconds\n', coreCount, elapsedTime);
    end

    % Load encoder output
    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');
    load('QPFrames.mat', 'QPFrames');

    tic
    decoder(nFrame, width, height, blockSize, VBSEnable, FMEEnable, ...
        QTCCoeffs, MDiffs, splits, QPFrames, visualizeVBS, visualizeRGB, visualizeMM, ...
        visualizeNRF, reconstructedY, parallelMode);
    elapsedTime = toc;
    if coreCount == 0
        fprintf('Decoding time without parallel processing: %f seconds\n', elapsedTime);
    else
        fprintf('Decoding time with %d core(s): %f seconds\n', coreCount, elapsedTime);
    end

    if parallelMode == 1
        delete(gcp('nocreate')); % Delete the parallel pool
    end
end