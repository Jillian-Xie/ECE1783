clc; clear; close all;

yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 5;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QP = 4;
I_Period = 8;
Lambda = getLambda(QP);

nRefFrames = 4;
VBSEnable = true;
FMEEnable = true;
FastME = false;

visualizeVBS = false;


% Test with FME Disabled
FMEEnable = false;
reconstructedYFileName_NoFME = 'reconstructedY_NoFME.mat';
Lambda = getLambda(QP);
runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS, reconstructedYFileName_NoFME, Lambda);
load(reconstructedYFileName_NoFME, 'reconstructedY');
reconstructedY_NoFME = reconstructedY; % Use the loaded variable

% Test with FME Enabled
FMEEnable = true;
reconstructedYFileName_FME = 'reconstructedY_FME.mat';
Lambda = getLambda(QP);
runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS, reconstructedYFileName_FME, Lambda);
load(reconstructedYFileName_FME, 'reconstructedY');
reconstructedY_FME = reconstructedY; % Use the loaded variable

% Calculate and compare PSNR
psnrNoFME = zeros(1, nFrame);
psnrFME = zeros(1, nFrame);
for i = 1:nFrame
    originalFrame = importYUV(yuvInputFileName, width, height, i);
    psnrNoFME(i) = calculatePSNR(originalFrame, reconstructedY_NoFME(:,:,i));
    psnrFME(i) = calculatePSNR(originalFrame, reconstructedY_FME(:,:,i));
end

% Display Results
disp('PSNR with FME Disabled:');
disp(psnrNoFME);
disp('PSNR with FME Enabled:');
disp(psnrFME);

function runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS, reconstructedYFileName, Lambda)
    reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, Lambda);
    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');
    decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, reconstructedY);

    % Save the reconstructed frames
    save(reconstructedYFileName, 'reconstructedY');
end


function psnrValue = calculatePSNR(originalFrame, reconstructedFrame)
    % Calculate the PSNR value between two frames
    mse = mean((double(originalFrame) - double(reconstructedFrame)).^2, 'all');
    psnrValue = 10 * log10(255^2 / mse);
end
