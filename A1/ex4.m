clc; clear; close all;

yuvInputFileName = 'foreman420_cif.yuv';
nFrame = uint32(300);
width  = uint32(352);
height = uint32(288);
blockSize = 8;
r = 2;
n = 1;
QP = 0;
I_Period = 1;

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

modeOutputPath = 'modeOutput\';
if ~exist(modeOutputPath,'dir')
    mkdir(modeOutputPath)
end

I_blockOutputPath = 'I_block\';
if ~exist(I_blockOutputPath,'dir')
    mkdir(I_blockOutputPath)
end

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
firstRefFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);
absoluteResidualNoMC = zeros(width, height, nFrame);
absoluteResidualWithMC = zeros(width, height, nFrame);
referenceFrame = firstRefFrame;

for currentFrameNum = 1:nFrame
    if rem(currentFrameNum,I_Period) == 1
        % first frame needs to be I frame
        [modeCell,I_blockCell, reconstructedY] = intraPrediction(paddingY(:,:,currentFrameNum), blockSize);
        referenceFrame = reconstructedY;

        modeFilePath = [modeOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(modeFilePath, 'modeCell');
        I_blockFilePath = [I_blockOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(I_blockFilePath, 'I_blockCell');

    else
        [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedY] = ex4_motionEstimate(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, n, QP);
        referenceFrame = reconstructedY;

        MVFilePath = [MVOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(MVFilePath, 'MVCell');
        approximatedResidualFilePath = [approximatedResidualOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(approximatedResidualFilePath, 'approximatedResidualCell');

    end
end