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


[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
firstRefFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);
absoluteResidualNoMC = zeros(height, width, nFrame);
absoluteResidualWithMC = zeros(height, width, nFrame);
referenceFrame = firstRefFrame;

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');
QTCCoeffs = strings([nFrame, widthBlockNum * heightBlockNum]);
MDiffs = strings([nFrame, 1]);

for currentFrameNum = 1:nFrame
    if rem(currentFrameNum,I_Period) == 1
        % first frame needs to be I frame
        [modeCell, QTCCoeffsFrame, MDiffsFrame, approximatedResidualCell, approximatedResidualFrame,reconstructedY] = intraPrediction(paddingY(:,:,currentFrameNum), blockSize, QP);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        referenceFrame = reconstructedY;

        modeFilePath = [modeOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(modeFilePath, 'modeCell');
    else
        [MVCell, QTCCoeffsFrame, MDiffsFrame, approximatedResidualCell, approximatedResidualFrame, reconstructedY] = ex4_motionEstimate(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, QP);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        referenceFrame = reconstructedY;

        MVFilePath = [MVOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(MVFilePath, 'MVCell');
    end
    approximatedResidualFilePath = [approximatedResidualOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
    save(approximatedResidualFilePath, 'approximatedResidualCell');
end

toc;