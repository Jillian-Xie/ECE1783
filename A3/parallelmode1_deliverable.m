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

% Load original Y component for PSNR calculation
[YOriginal, ~, ~] = importYUV(yuvInputFileName, width, height, nFrame);

% Core counts to test including non-parallel mode (0)
coreCounts = [0, 1, 2, 4];

% Initialize arrays for PSNR and bit count
psnrValues = zeros(1, length(coreCounts));
totalBitSizes = zeros(1, length(coreCounts));

% Load statistics if RCFlag >= 1
if RCFlag >= 1 
    statistics = load('CIFStatistics.mat', 'CIFStatistics');
    statistics = statistics.CIFStatistics;
else
    statistics = {};
end

for idx = 1:length(coreCounts)
    coreCount = coreCounts(idx);
    
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
    fprintf('Encoding time: %f seconds\n', elapsedTime);

    % Load encoder output and calculate bit size
    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');
    totalBitSizes(idx) = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame);

% Calculate PSNR
psnrValue = 0;
for i = 1:nFrame
    % Convert frames to double for PSNR calculation
    frameOriginal = double(YOriginal(:,:,i));
    frameReconstructed = double(reconstructedY(:,:,i));
    
    % Normalize to [0, 1] range if original images were in uint8 format
    if isa(YOriginal, 'uint8')
        frameOriginal = frameOriginal / 255;
    end
    if isa(reconstructedY, 'uint8')
        frameReconstructed = frameReconstructed / 255;
    end

    % Calculate PSNR
    psnrValue = psnrValue + psnr(frameReconstructed, frameOriginal);
end
psnrValues(idx) = psnrValue / nFrame;




    if parallelMode == 1
        delete(gcp('nocreate')); % Delete the parallel pool
    end
end

% Display PSNR and Bit Count results
for idx = 1:length(coreCounts)
    fprintf('Core Count: %d, PSNR: %.2f dB, Bit Count: %d bits\n', ...
            coreCounts(idx), psnrValues(idx), totalBitSizes(idx));
end

function totalBits = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame)
    % Calculate total bit size for all frames
    totalBits = 0;
    for i = 1:nFrame
        totalBits = totalBits + sum(strlength(QTCCoeffs(i,:)), "all") + sum(strlength(MDiffs(i,:)), "all") + sum(strlength(splits(i,:)), "all");
    end
end

