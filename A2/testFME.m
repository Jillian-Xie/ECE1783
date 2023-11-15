clc; clear; close all;

yuvInputFileName = 'synthetic.yuv';
nFrame = 10;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 2;
QP = 4;
I_Period = 3;

nRefFrames = 2;
VBSEnable = false;
FMEEnable = true;
FastME = false;
visualizeVBS = VBSEnable && true;



% Test with FME Disabled
FMEEnable = false;
runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS);
load('reconstructedY.mat', 'reconstructedY');
reconstructedY_NoFME = reconstructedY; % Use the loaded variable

% Test with FME Enabled
FMEEnable = true;
runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS);
load('reconstructedY.mat', 'reconstructedY');
reconstructedY_FME = reconstructedY; % Use the loaded variable

% Calculate and compare PSNR
psnrNoFME = zeros(1, nFrame);
psnrFME = zeros(1, nFrame);
for i = 1:nFrame
    originalFrame = importYUVFrame(yuvInputFileName, width, height, i);
    psnrNoFME(i) = calculatePSNR(originalFrame, reconstructedY_NoFME(:,:,i));
    psnrFME(i) = calculatePSNR(originalFrame, reconstructedY_FME(:,:,i));
end

% Display Results
disp('PSNR with FME Disabled:');
disp(psnrNoFME);
disp('PSNR with FME Enabled:');
disp(psnrFME);

function runTest(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, visualizeVBS)
    reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME);
    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');
    decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, reconstructedY);

    % The reconstructed frames are assumed to be saved in the 'decoder' function
end

function frame = importYUVFrame(yuvFileName, width, height, frameNum)
    % Imports a single frame from a YUV file
    fid = fopen(yuvFileName, 'r');
    fseek(fid, 1.5 * (frameNum - 1) * width * height, 'bof');
    yuv = fread(fid, 1.5 * width * height, '*uint8');
    fclose(fid);

    yuv = reshape(yuv, width, []);
    frame = yuv(:, 1:height)';
end

function psnrValue = calculatePSNR(originalFrame, reconstructedFrame)
    % Calculate the PSNR value between two frames
    mse = mean((double(originalFrame) - double(reconstructedFrame)).^2, 'all');
    psnrValue = 10 * log10(255^2 / mse);
end
