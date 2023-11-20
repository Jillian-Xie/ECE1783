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

% Initialize arrays for multi-reference frames (nRefFrames = 4)
psnrValuesMultiRef = zeros(length(QPs), 1);
encTimesMultiRef = zeros(size(psnrValuesMultiRef));
decTimesMultiRef = zeros(size(psnrValuesMultiRef));
bitSizesMultiRef = zeros(size(psnrValuesMultiRef));

% Initialize arrays for no features (nRefFrames = 1)
psnrValuesNoFeatures = zeros(length(QPs), 1);
encTimesNoFeatures = zeros(size(psnrValuesNoFeatures));
decTimesNoFeatures = zeros(size(psnrValuesNoFeatures));
bitSizesNoFeatures = zeros(size(psnrValuesNoFeatures));

for q = 1:length(QPs)
    QP = QPs(q);
    Lambda = getLambda(QP);

    % Test with multi-reference frames enabled (nRefFrames = 4)
    [bitSizesMultiRef(q), encTimesMultiRef(q), decTimesMultiRef(q), psnrValuesMultiRef(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, 4, false, false, false, false, Lambda);

    % Test with no features (nRefFrames = 1)
    [bitSizesNoFeatures(q), encTimesNoFeatures(q), decTimesNoFeatures(q), psnrValuesNoFeatures(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, 1, false, false, false, false, Lambda);
end

% Plotting the RD Curve
figure;
plot(bitSizesMultiRef, psnrValuesMultiRef, 'b-o', bitSizesNoFeatures, psnrValuesNoFeatures, 'r-*');
title('Rate-Distortion Curve for Multi Reference Frames');
xlabel('Total Size in Bits');
ylabel('PSNR (dB)');
legend('Multi-Ref Frames', 'No Features', 'Location', 'southeast')

% Plotting the Encoding Times
figure;
plot(QPs, encTimesMultiRef, 'b-o', QPs, encTimesNoFeatures, 'r-*');
title('Encoding Times for Multi Reference Frames');
xlabel('QP');
ylabel('Time (s)');
legend('Multi-Ref Frames', 'No Features');

% Plotting the Decoding Times
figure;
plot(QPs, decTimesMultiRef, 'b-o', QPs, decTimesNoFeatures, 'r-*');
title('Decoding Times for Multi Reference Frames');
xlabel('QP');
ylabel('Time (s)');
legend('Multi-Ref Frames', 'No Features');

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
