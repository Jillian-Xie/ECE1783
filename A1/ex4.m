clc; clear; close all;

tic;

yuvInputFileName = 'foreman420_cif.yuv';
nFrame = uint32(10);
width  = uint32(352);
height = uint32(288);
blockSize = 8;
r = 2;
QP = 0;
I_Period = 2;


[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
referenceFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

QTCCoeffs = strings([nFrame, widthBlockNum * heightBlockNum]);
MDiffs = strings([nFrame, 1]);

for currentFrameNum = 1:nFrame
    if rem(currentFrameNum,I_Period) == 1
        % first frame needs to be I frame
        [QTCCoeffsFrame, MDiffsFrame, reconstructedY] = intraPrediction(paddingY(:,:,currentFrameNum), blockSize, QP);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        referenceFrame = reconstructedY;
    else
        [QTCCoeffsFrame, MDiffsFrame, reconstructedY] = ex4_motionEstimate(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, QP);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        referenceFrame = reconstructedY;
    end
end

save('QTCCoeffs.mat', 'QTCCoeffs');
save('MDiffs.mat', 'MDiffs');

toc;