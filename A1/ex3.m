clc; clear; close all; 

yuvInputFileName = 'foreman420_cif.yuv';
MVOutputPath = 'MVOutput\';
nFrame = uint32(300);
width  = uint32(352);
height = uint32(288);
blockSize = 8;
r = 2;

if ~exist(MVOutputPath,'dir')
    mkdir(MVOutputPath)
end

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
firstRefFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);

for currentFrameNum = 1:nFrame
    if currentFrameNum == 1
        MVCell = motionEstimate(firstRefFrame, paddingY(:,:,currentFrameNum), blockSize, r);
        MVFilePath = [MVOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(MVFilePath, 'MVCell');
    else
        MVCell = motionEstimate(paddingY(:,:,currentFrameNum-1), paddingY(:,:,currentFrameNum), blockSize, r);
        MVFilePath = [MVOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(MVFilePath, 'MVCell');
    end
end