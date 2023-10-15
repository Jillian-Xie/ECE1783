clc; clear; close all; 

yuvInputFileName = 'foreman420_cif.yuv';
nFrame = uint32(300);
width  = uint32(352);
height = uint32(288);
blockSize = 8;
r = 2;
n = 1;

MVOutputPath = 'MVOutput\';
if ~exist(MVOutputPath,'dir')
    mkdir(MVOutputPath)
end

approximatedResidualOutputPath = 'approximatedResidualOutput\';
if ~exist(approximatedResidualOutputPath,'dir')
    mkdir(approximatedResidualOutputPath)
end

absoluteResidualNoMCOutputPath = 'absoluteResidualNoMCOutput\';
if ~exist(absoluteResidualNoMCOutputPath,'dir')
    mkdir(absoluteResidualNoMCOutputPath)
end

absoluteResidualWithMCOutputPath = 'absoluteResidualWithMCOutput\';
if ~exist(absoluteResidualWithMCOutputPath,'dir')
    mkdir(absoluteResidualWithMCOutputPath)
end

encoderReconstructionOutputPath = 'encoderReconstructionOutput\';
if ~exist(encoderReconstructionOutputPath,'dir')
    mkdir(encoderReconstructionOutputPath)
end

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
firstRefFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);
absoluteResidualNoMC = zeros(width, height, nFrame);
referenceFrame = firstRefFrame;

for currentFrameNum = 1:nFrame
    absoluteResidualNoMC(:,:,currentFrameNum) = uint8(abs(paddingY(1:width,1:height,currentFrameNum) - referenceFrame(1:width,1:height)));

    [MVCell, approximatedResidualCell, reconstructedY] = motionEstimate(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, n);
    referenceFrame = reconstructedY;
    
    MVFilePath = [MVOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
    save(MVFilePath, 'MVCell');
    approximatedResidualFilePath = [approximatedResidualOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
    save(approximatedResidualFilePath, 'approximatedResidualCell');

    YOnlyFilePath = [encoderReconstructionOutputPath, sprintf('%04d',currentFrameNum), '.yuv'];
    fid = createOrClearFile(YOnlyFilePath);
    fwrite(fid,uint8(reconstructedY(:,:)),'uchar');
    fclose(fid);
end

% convertToRGBandDump(absoluteResidualNoMC, U, V, width, height ,nFrame, absoluteResidualNoMCOutputPath);