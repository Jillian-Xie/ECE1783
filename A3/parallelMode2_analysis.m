clc; clear; close all;

% Configuration
yuvInputFileName = 'CIF.yuv';
nFrame = 21;
width = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QPs = [0 1 2 3 4 5 6 7 8 9 10 11];
I_Period = 10;
nRefFrames = 1;
VBSEnable = true;
FMEEnable = true;
FastME = true;
RCFlag = 0;
targetBR = 1140480; % bps
frameRate = 30;
dQPLimit = 2;

% Initialize arrays for storing results
results = struct();
configurations = [struct('mode', 0, 'cores', 0), ...
                  struct('mode', 2, 'cores', 1), ...
                  struct('mode', 2, 'cores', 2), ...
                  struct('mode', 2, 'cores', 4)];
nConfigs = length(configurations);

% Load the original Y component for PSNR calculation
[YOriginal, ~, ~] = importYUV(yuvInputFileName, width, height, nFrame);

% Loop for each configuration
for cfgIdx = 1:nConfigs
    config = configurations(cfgIdx);
    
    if config.cores > 0 && config.mode == 2
        parpool(config.cores);
    end

    psnrValues = zeros(length(QPs), 1);
    totalBitSizes = zeros(length(QPs), 1);
    encodingTimes = zeros(length(QPs), 1);

    % Loop through each QP value
    for qpIdx = 1:length(QPs)
        QP = QPs(qpIdx);

        % Select and run the encoder function based on parallel mode
        tic; % Start timing
        if config.mode == 0
            reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, targetBR, frameRate, QPs, {}, 0, dQPLimit);
        else
            % Assuming 'statistics' variable is set up as required
            statistics = {}; % Placeholder, replace with actual statistics setup if needed
            reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, targetBR, frameRate, QPs, statistics, config.mode, dQPLimit);
        end
        elapsedTime = toc; % End timing

        % Ensure reconstructedY is in uint8 format
        if ~isa(reconstructedY, 'uint8')
            reconstructedY = uint8(reconstructedY);
        end

        % Load encoder output for PSNR and Bit Size calculations
        load('QTCCoeffs.mat', 'QTCCoeffs');
        load('MDiffs.mat', 'MDiffs');
        load('splits.mat', 'splits');

        % PSNR Calculation
        psnrSum = 0;
        for i = 1:nFrame
            psnrSum = psnrSum + psnr(reconstructedY(:, :, i), YOriginal(:, :, i));
        end
        avgPSNR = psnrSum / nFrame;

        % Bit Size Calculation
        totalBitSize = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame);

        % Store results
        psnrValues(qpIdx) = avgPSNR;
        totalBitSizes(qpIdx) = totalBitSize;
        encodingTimes(qpIdx) = elapsedTime;
    end

    % Store results for this configuration
    results(cfgIdx).mode = config.mode;
    results(cfgIdx).cores = config.cores;
    results(cfgIdx).psnr = psnrValues;
    results(cfgIdx).bitSizes = totalBitSizes;
    results(cfgIdx).encodingTimes = encodingTimes;

    if config.cores > 0 && config.mode == 2
        delete(gcp('nocreate'));
    end
end

% Printing Encoding Time and Bit Count Comparisons
fprintf('Encoding Time and Bit Count Comparisons:\n');
for cfgIdx = 1:nConfigs
    config = results(cfgIdx);
    fprintf('Parallel Mode: %d, Cores: %d\n', config.mode, config.cores);
    for qpIdx = 1:length(QPs)
        fprintf('QP: %d, Encoding Time: %.2f seconds, Bit Count: %d bits\n', ...
                QPs(qpIdx), config.encodingTimes(qpIdx), config.bitSizes(qpIdx));
    end
    fprintf('\n');
end

% Function to calculate total bit size
function totalBits = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame)
    % Calculate total bit size for all frames
    totalBits = 0;
    for i = 1:nFrame
        totalBits = totalBits + sum(strlength(QTCCoeffs(i,:)), 'all') + sum(strlength(MDiffs(i,:)), 'all') + sum(strlength(splits(i,:)), 'all');
    end
end
