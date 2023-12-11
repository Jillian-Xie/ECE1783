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
targetBR = 2400000; % bps
frameRate = 30;
dQPLimit = 2;
statistics = [];

% Initialize arrays for storing results
results = struct();
configurations = [struct('mode', 0, 'cores', 0), ...
                  struct('mode', 2, 'cores', 1), ...
                  struct('mode', 2, 'cores', 2), ...
                  struct('mode', 2, 'cores', 4)];
nConfigs = length(configurations);

% Load the original Y component for PSNR calculation
[YOriginal, ~, ~] = importYUV(yuvInputFileName, width, height, nFrame);
parpool(2);
% Loop for each configuration
for cfgIdx = 1:nConfigs
    config = configurations(cfgIdx);
    
    if config.cores > 0
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
            reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, ...
                r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, ...
                targetBR, frameRate, QPs, statistics, 0, dQPLimit);
        else
            reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, ...
                r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, ...
                targetBR, frameRate, QPs, statistics, 2, dQPLimit);
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

    if config.cores > 0
        delete(gcp('nocreate'));
    end
end

% Plotting
figure;
subplot(2,1,1); % PSNR and Bit Size plot
hold on;
subplot(2,1,2); % Encoding Time plot
hold on;

colors = ['b', 'r', 'g', 'k']; % Different colors for different plots
legendEntries = {};

% Plot for each configuration
for cfgIdx = 1:nConfigs
    config = results(cfgIdx);
    colorIdx = mod(cfgIdx - 1, length(colors)) + 1;
    plotStyle = sprintf('%s-*', colors(colorIdx));

    subplot(2,1,1);
    plot(config.bitSizes, config.psnr, plotStyle);

    subplot(2,1,2);
    plot(QPs, config.encodingTimes, plotStyle);

    if config.mode == 0
        legendEntries{end+1} = 'Parallel Mode 0';
    else
        legendEntries{end+1} = sprintf('Parallel Mode 1, %d Workers', config.cores);
    end
end

subplot(2,1,1);
title('RD-Plots for Different Parallel Modes and Core Counts');
xlabel('Total Bit Size (bits)');
ylabel('PSNR (dB)');
legend(legendEntries, 'Location', 'southeast');

subplot(2,1,2);
title('Encoding Times for Different Parallel Modes and Core Counts');
xlabel('QP');
ylabel('Encoding Time (s)');
legend(legendEntries, 'Location', 'northeast');

hold off;

% Function to calculate total bit size
function totalBits = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame)
    % Calculate total bit size for all frames
    totalBits = 0;
    for i = 1:nFrame
        totalBits = totalBits + sum(strlength(QTCCoeffs(i,:)), 'all') + sum(strlength(MDiffs(i,:)), 'all') + sum(strlength(splits(i,:)), 'all');
    end
end
