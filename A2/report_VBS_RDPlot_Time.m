clc; clear; close all;

% Configuration Info
yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 10; % Use first 10 frames
width  = 352;
height = 288;
blockSize = 16; % Fixed block size
r = 4; % Fixed search range
I_Period = 8; % Fixed I_Period
QPs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]; % Array of QP values
nRefFrames = 1;
VBSEnable = false;
FMEEnable = false;
FastME = false;
visualizeVBS = VBSEnable && false;

% Initialize arrays
psnrValuesVBS = zeros(length(QPs), 1);
psnrValuesNoVBS = zeros(length(QPs), 1);
encTimesVBS = zeros(size(psnrValuesVBS));
encTimesNoVBS = zeros(size(psnrValuesNoVBS));
decTimesVBS = zeros(size(psnrValuesVBS));
decTimesNoVBS = zeros(size(psnrValuesNoVBS));
bitSizesVBS = zeros(size(psnrValuesVBS));
bitSizesNoVBS = zeros(size(psnrValuesNoVBS));

for q = 1:length(QPs)
    QP = QPs(q);
    Lambda = getLambda(QP);

    % Test with VBSEnable enabled
    VBSEnable = true;
    [bitSizesVBS(q), encTimesVBS(q), decTimesVBS(q), psnrValuesVBS(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS, Lambda);

    % Test with VBSEnable disabled
    VBSEnable = false;
    [bitSizesNoVBS(q), encTimesNoVBS(q), decTimesNoVBS(q), psnrValuesNoVBS(q)] = runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS, Lambda);
end

% Plotting the RD Curve
figure;
plot(bitSizesVBS, psnrValuesVBS, 'b-o', bitSizesNoVBS, psnrValuesNoVBS, 'r-*');
title('Rate-Distortion Curve for VBS');
xlabel('Total Size in Bits');
ylabel('PSNR (dB)');
legend('With VBS', 'No Features', 'Location', 'southeast');

% Plotting the Encoding Times
figure;
plot(QPs, encTimesVBS, 'b-o', QPs, encTimesNoVBS, 'r-*');
title('Encoding Times for VBS');
xlabel('QP');
ylabel('Time (s)');
legend('With VBS', 'No Features');

% Plotting the Decoding Times
figure;
plot(QPs, decTimesVBS, 'b-o', QPs, decTimesNoVBS, 'r-*');
title('Decoding Times for VBS');
xlabel('QP');
ylabel('Time (s)');
legend('With VBS', 'No Features');

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


