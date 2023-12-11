clc; clear; close all;

% Configuration
yuvInputFileName = 'CIF.yuv';
nFrame = 21;
width = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QPs = [1 4 7 10];
I_Period = 10;
nRefFrames = 1;
VBSEnable = true;
FMEEnable = true;
FastME = true;
RCFlag = 0;
targetBR = 2400000; % bps
frameRate = 30;
dQPLimit = 2;
statistics = {}; % Placeholder for statistics

% Initialize arrays for storing results
results = struct();
parallelModes = [0, 1, 2, 3];
coreCount = 4; % Using 4 workers

% Start parallel pool
parpool(coreCount);

% Load the original Y component for PSNR calculation
[YOriginal, ~, ~] = importYUV(yuvInputFileName, width, height, nFrame);

% Loop for each parallel mode
for i = 1:length(parallelModes)
    parallelMode = parallelModes(i);
    psnrValues = zeros(length(QPs), 1);
    totalBitSizes = zeros(length(QPs), 1);
    encodingTimes = zeros(length(QPs), 1);

    % Loop through each QP value
    for qpIdx = 1:length(QPs)
        QP = QPs(qpIdx);

        % Select and run the encoder function based on parallel mode
        tic; % Start timing
        if parallelMode == 0 || parallelMode == 2
            % Normal encoder for parallel modes 0 and 2
            reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, targetBR, frameRate, QPs, statistics, parallelMode, dQPLimit);
        elseif parallelMode == 1
            % Parallel mode 1 encoder
            reconstructedY = encoder_parallelMode1(yuvInputFileName, nFrame, width, height, blockSize, QP);
        else
            % Parallel mode 3 encoder
            reconstructedY = encoder_parallelMode3(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, VBSEnable, FMEEnable, FastME);
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

    % Store results for this parallel mode
    results(parallelMode+1).mode = parallelMode;
    results(parallelMode+1).psnr = psnrValues;
    results(parallelMode+1).bitSizes = totalBitSizes;
    results(parallelMode+1).encodingTimes = encodingTimes;
end

% Delete the parallel pool
delete(gcp('nocreate'));

% Plotting
figure;
subplot(2,1,1); % PSNR and Bit Size plot
hold on;
subplot(2,1,2); % Encoding Time plot
hold on;

colors = ['b', 'r', 'g', 'k']; % Different colors for different plots
legendEntries = {};

% Plot for each parallel mode
for i = 1:length(parallelModes)
    config = results(i);
    colorIdx = mod(i - 1, length(colors)) + 1;
    plotStyle = sprintf('%s-*', colors(colorIdx));

    subplot(2,1,1);
    plot(config.bitSizes, config.psnr, plotStyle);

    subplot(2,1,2);
    plot(QPs, config.encodingTimes, plotStyle);

    legendEntries{end+1} = sprintf('Parallel Mode %d', config.mode);
end

subplot(2,1,1);
title('RD-Plots for Different Parallel Modes');
xlabel('Total Bit Size (bits)');
ylabel('PSNR (dB)');
legend(legendEntries, 'Location', 'southeast');

subplot(2,1,2);
title('Encoding Times for Different Parallel Modes');
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
