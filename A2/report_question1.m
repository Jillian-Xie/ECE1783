clc; clear; close all;

% Configuration Info
yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 10; % Use first 10 frames
width  = 352;
height = 288;
I_Period = 8; % Fixed I_Period
QPs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]; % Array of QP values

% Initialize arrays for PSNR, Bit Sizes, and Encoding Times
psnrValues = zeros(length(QPs), 6);
totalBitSizes = zeros(length(QPs), 6);
encTimes = zeros(length(QPs), 6);

for q = 1:length(QPs)
    QP = QPs(q);
    Lambda = getLambda(QP);

    % Feature combinations + No feature
    featureCombos = [
        struct('blockSize', 16, 'r', 4, 'nRefFrames', 1, 'VBSEnable', true, 'FMEEnable', false, 'FastME', false); % VBS only
        struct('blockSize', 16, 'r', 4, 'nRefFrames', 1, 'VBSEnable', false, 'FMEEnable', true, 'FastME', false); % FME only
        struct('blockSize', 16, 'r', 4, 'nRefFrames', 4, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false); % MultiRefFrame only
        struct('blockSize', 8, 'r', 4, 'nRefFrames', 1, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);  % Smaller block size
        struct('blockSize', 16, 'r', 8, 'nRefFrames', 1, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false); % Larger search range
        struct('blockSize', 16, 'r', 4, 'nRefFrames', 1, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false)  % No features
    ];

    for combo = 1:size(featureCombos, 1)
        settings = featureCombos(combo);
        [bitSize, eTime, ~, psnrVal] = runTest(yuvInputFileName, nFrame, width, height, settings.blockSize, settings.r, QP, I_Period, settings.nRefFrames, settings.VBSEnable, settings.FMEEnable, settings.FastME, false, Lambda);
        psnrValues(q, combo) = psnrVal;
        totalBitSizes(q, combo) = bitSize;
        encTimes(q, combo) = eTime;
    end
end

% Plotting PSNR with Total File Size on X-axis
figure;
plot(totalBitSizes, psnrValues);
title('PSNR Comparison with Total File Size');
xlabel('Total Size in Bits');
ylabel('PSNR (dB)');
legend('VBS Only', 'FME Only', 'MultiRefFrame Only', 'Block Size=8', 'Search Range=8', 'No Features', 'Location', 'southeast');

% Plotting Encoding Times with QPs on X-axis
figure;
plot(QPs, encTimes);
title('Encoding Times Comparison');
xlabel('QP');
ylabel('Time (s)');
legend('EncTime - VBS Only', 'EncTime - FME Only', 'EncTime - MultiRefFrame Only', 'EncTime - Block Size=8', 'EncTime - Search Range=8', 'EncTime - No Features', 'Location', 'northeast');

function [bitSize, encTime, decTime, psnrValue] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS, Lambda)
    % Run encoder
    tic;
    reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, Lambda);
    encTime = toc;

    % Load necessary files for decoding and calculate bit size
    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');
    bitSize = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame);
    visualizeVBS = false;
    visualizeRGB = false;
    visualizeMM = false;
    visualizeNRF = false;

    % Run decoder
    tic;
    decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, visualizeRGB, visualizeMM, visualizeNRF, reconstructedY);
    decTime = toc;

    % Calculate PSNR
    YOutput = importYOnly(['DecoderOutput' filesep 'outputYUV.yuv'], width, height, nFrame);
    [YOriginal, ~, ~] = importYUV(yuvInputFileName, width, height, nFrame);
    psnrValue = 0;
    for i = 1:nFrame
        psnrValue = psnrValue + psnr(YOutput(:,:,i), YOriginal(:,:,i));
    end
    psnrValue = psnrValue / nFrame;
end

function totalBits = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame)
    % Calculate total bit size for all frames
    totalBits = 0;
    for i = 1:nFrame
        totalBits = totalBits + sum(strlength(QTCCoeffs(i,:)), "all") + sum(strlength(MDiffs(i,:)), "all") + sum(strlength(splits(i,:)), "all");
    end
end

