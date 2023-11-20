clc; clear; close all;

% Configuration Info
yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 10; % Use first 10 frames
width  = 352;
height = 288;
blockSize = 16; % Fixed block size
r = 4; % Fixed search range
I_Period = 8; % Fixed I_Period
QPs = [1,4,7,10]; % Array of QP values

% Initialize arrays for feature comparison
psnrValuesAllFeatures = zeros(length(QPs), 1);
psnrValuesNoFeatures = zeros(length(QPs), 1);
psnrValuesNRF = zeros(length(QPs), 1);
psnrValuesVBS = zeros(length(QPs), 1);
psnrValuesFME = zeros(length(QPs), 1);
psnrValuesFastME = zeros(length(QPs), 1);

encTimesAllFeatures = zeros(size(psnrValuesAllFeatures));
encTimesNoFeatures = zeros(size(psnrValuesNoFeatures));
encTimesNRF = zeros(size(psnrValuesNRF));
encTimesVBS = zeros(size(psnrValuesVBS));
encTimesFME = zeros(size(psnrValuesFME));
encTimesFastME = zeros(size(psnrValuesFastME));

decTimesAllFeatures = zeros(size(psnrValuesAllFeatures));
decTimesNoFeatures = zeros(size(psnrValuesNoFeatures));
decTimesNRF = zeros(size(psnrValuesNRF));
decTimesVBS = zeros(size(psnrValuesVBS));
decTimesFME = zeros(size(psnrValuesFME));
decTimesFastME = zeros(size(psnrValuesFastME));

bitSizesAllFeatures = zeros(size(psnrValuesAllFeatures));
bitSizesNoFeatures = zeros(size(psnrValuesNoFeatures));
bitSizesNRF = zeros(size(psnrValuesNRF));
bitSizesVBS = zeros(size(psnrValuesVBS));
bitSizesFME = zeros(size(psnrValuesFME));
bitSizesFastME = zeros(size(psnrValuesFastME));

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

    VBSEnable = true;
    FMEEnable = false;
    FastME = false;
    nRefFrames = 1;
    [bitSizesVBS(q), encTimesVBS(q), decTimesVBS(q), psnrValuesVBS(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, false, Lambda);

    VBSEnable = false;
    FMEEnable = true;
    FastME = false;
    nRefFrames = 1;
    [bitSizesFastME(q), encTimesFastME(q), decTimesFastME(q), psnrValuesFastME(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, false, Lambda);

    VBSEnable = false;
    FMEEnable = true;
    FastME = false;
    nRefFrames = 1;
    [bitSizesFME(q), encTimesFME(q), decTimesFME(q), psnrValuesFME(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, false, Lambda);

    VBSEnable = false;
    FMEEnable = false;
    FastME = false;
    nRefFrames = 4;
    [bitSizesNRF(q), encTimesNRF(q), decTimesNRF(q), psnrValuesNRF(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, false, Lambda);

end

% Plotting the RD Curve for Feature Comparison
figure;
plot(bitSizesNoFeatures, psnrValuesNoFeatures, 'r-', bitSizesAllFeatures, psnrValuesAllFeatures, 'c-', bitSizesVBS, psnrValuesVBS, 'g-', bitSizesNRF, psnrValuesNRF, 'b-', bitSizesFME, psnrValuesFME, 'm-', bitSizesFastME, psnrValuesFastME, 'y-');
title('Rate-Distortion Curve');
xlabel('Total Size in Bits');
ylabel('PSNR (dB)');
legend('No Features', 'All Features', 'VBS', 'nRefFrames', 'FME', 'FastME', 'Location', 'southeast');

% Plotting the Encoding Times for Feature Comparison
figure;
plot(QPs, encTimesNoFeatures, 'r-', QPs, encTimesAllFeatures, 'c-', QPs, encTimesVBS, 'g-', QPs, encTimesNRF, 'b-', QPs, encTimesFME, 'm-', QPs, encTimesFastME, 'y-');
title('Encoding Times');
xlabel('QP');
ylabel('Time (s)');
legend('No Features', 'All Features', 'VBS', 'nRefFrames', 'FME', 'FastME', 'Location', 'southeast');

% Plotting the Decoding Times for Feature Comparison
figure;
plot(QPs, decTimesNoFeatures, 'r-', QPs, decTimesAllFeatures, 'c-', QPs, decTimesVBS, 'g-', QPs, decTimesNRF, 'b-', QPs, decTimesFME, 'm-', QPs, decTimesFastME, 'y-');
title('Decoding Times');
xlabel('QP');
ylabel('Time (s)');
legend('No Features', 'All Features', 'VBS', 'nRefFrames', 'FME', 'FastME', 'Location', 'southeast');

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
    psnrValue = psnr(YOutput, YOriginal);
end

function totalBits = calculateBitSize(QTCCoeffs, MDiffs, splits, nFrame)
    % Calculate total bit size for all frames
    totalBits = 0;
    for i = 1:nFrame
        totalBits = totalBits + sum(strlength(QTCCoeffs(i,:)), "all") + sum(strlength(MDiffs(i,:)), "all") + sum(strlength(splits(i,:)), "all");
    end
end
