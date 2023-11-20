clc; clear; close all;

% Configuration Info
yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 10; % Use first 10 frames
width  = 352;
height = 288;
blockSize = 16; % Fixed block size
r = 4; % Fixed search range
I_Period = 8; % Fixed I_Period
QPs = [1,2,3,4,5,6,7,8,9,10,11]; % Array of QP values

% Initialize arrays for feature comparison
psnrValuesAllFeatures = zeros(length(QPs), 1);
psnrValuesNoFeatures = zeros(length(QPs), 1);
encTimesAllFeatures = zeros(size(psnrValuesAllFeatures));
encTimesNoFeatures = zeros(size(psnrValuesNoFeatures));
decTimesAllFeatures = zeros(size(psnrValuesAllFeatures));
decTimesNoFeatures = zeros(size(psnrValuesNoFeatures));
bitSizesAllFeatures = zeros(size(psnrValuesAllFeatures));
bitSizesNoFeatures = zeros(size(psnrValuesNoFeatures));

for q = 1:length(QPs)
    QP = QPs(q);
    Lambda = getLambda(QP);

    % Test with no features enabled
    VBSEnable = false;
    FMEEnable = false;
    FastME = false;
    nRefFrames = 1;
    [bitSizesNoFeatures(q), encTimesNoFeatures(q), decTimesNoFeatures(q), psnrValuesNoFeatures(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, false, Lambda);

    % Test with all features enabled
    VBSEnable = true;
    FMEEnable = true;
    FastME = true;
    nRefFrames = 4;
    [bitSizesAllFeatures(q), encTimesAllFeatures(q), decTimesAllFeatures(q), psnrValuesAllFeatures(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, false, Lambda);
end

% Plotting the RD Curve for Feature Comparison
figure;
plot(bitSizesNoFeatures, psnrValuesNoFeatures, 'b-o', bitSizesAllFeatures, psnrValuesAllFeatures, 'r-*');
title('Rate-Distortion Curve: No Features vs All Features');
xlabel('Total Size in Bits');
ylabel('PSNR (dB)');
legend('No Features', 'All Features', 'Location', 'southeast');

% Plotting the Encoding Times for Feature Comparison
figure;
plot(QPs, encTimesNoFeatures, 'b-o', QPs, encTimesAllFeatures, 'r-*');
title('Encoding Times: No Features vs All Features');
xlabel('QP');
ylabel('Time (s)');
legend('No Features', 'All Features');

% Plotting the Decoding Times for Feature Comparison
figure;
plot(QPs, decTimesNoFeatures, 'b-o', QPs, decTimesAllFeatures, 'r-*');
title('Decoding Times: No Features vs All Features');
xlabel('QP');
ylabel('Time (s)');
legend('No Features', 'All Features');

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

