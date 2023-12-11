clc; clear; close all;
parpool(4);

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

% Initialize arrays for storing results
psnrValuesMode0 = zeros(length(QPs), 1);
totalBitSizesMode0 = zeros(length(QPs), 1);
psnrValuesMode1 = zeros(length(QPs), 1);
totalBitSizesMode1 = zeros(length(QPs), 1);

% Load the original Y component for PSNR calculation
[YOriginal, ~, ~] = importYUV(yuvInputFileName, width, height, nFrame);

% Loop for each parallel mode
for parallelMode = [0, 1]
    % Loop through each QP value
    for qpIdx = 1:length(QPs)
        QP = QPs(qpIdx);

        % Select and run the encoder function based on parallel mode
        if parallelMode == 0
            reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, targetBR, frameRate, QPs, {}, parallelMode, dQPLimit);
        else
            reconstructedY = encoder_parallelMode1(yuvInputFileName, nFrame, width, height, blockSize, QP);
        end
        
        if ~isa(reconstructedY, 'uint8')
                reconstructedY = uint8(reconstructedY);
        end

        % PSNR Calculation
        psnrSum = 0;
        for i = 1:nFrame
            psnrSum = psnrSum + psnr(reconstructedY(:, :, i), YOriginal(:, :, i));
        end
        avgPSNR = psnrSum / nFrame;

        % Bit Size Calculation
        load('QTCCoeffs.mat', 'QTCCoeffs');
        load('MDiffs.mat', 'MDiffs');
        load('splits.mat', 'splits');
        totalBitSize = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame);

        % Store results in respective arrays
        if parallelMode == 0
            psnrValuesMode0(qpIdx) = avgPSNR;
            totalBitSizesMode0(qpIdx) = totalBitSize;
        else
            psnrValuesMode1(qpIdx) = avgPSNR;
            totalBitSizesMode1(qpIdx) = totalBitSize;
        end
    end
end

delete(gcp('nocreate'));

% Plotting RD-plot for Parallel Mode 0
plot(totalBitSizesMode0, psnrValuesMode0, 'b-o'); % Blue circles
hold on; % This command retains the current plot so that the next plot is added to it

% Plotting RD-plot for Parallel Mode 1
plot(totalBitSizesMode1, psnrValuesMode1, 'r-*'); % Red stars

% Adding title and labels
title('RD-Plots for Parallel Modes 0 and 1');
xlabel('Total Bit Size (bits)');
ylabel('PSNR (dB)');

legend('Parallel Mode 0', 'Parallel Mode 1', 'Location', 'southeast');

% Function to calculate total bit size
function totalBits = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame)
    % Calculate total bit size for all frames
    totalBits = 0;
    for i = 1:nFrame
        totalBits = totalBits + sum(strlength(QTCCoeffs(i,:)), 'all') + sum(strlength(MDiffs(i,:)), 'all') + sum(strlength(splits(i,:)), 'all');
    end
end

