function reconstructedY = encoder(yuvInputFileName, nFrame, width, height, ...
    blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, ...
    FastME, RCFlag, targetBR, frameRate, QPs, statistics)

[Y,~,~] = importYUV(yuvInputFileName, width, height ,nFrame);

% Padding if the width and/or height of the frame is not divisible by i
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);

% the reference frame for intra- or inter-frame prediction
referenceFrames(1:size(paddingY,1),1:size(paddingY,2),1) = int32(128); 
interpolateReferenceFrames(1:2*height-1, 1:2*width-1, 1) = int32(128);

% Reconstructed Y-only frames (with padding)
reconstructedY(1:size(paddingY,1),1:size(paddingY,2),1:nFrame) = paddingY;

interpolateRefFrames(1:2*height-1, 1:2*width-1, nFrame) = int32(0);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

QTCCoeffs = strings([nFrame, widthBlockNum * heightBlockNum * 4]);
MDiffs = strings([nFrame, 1]);
splits = strings([nFrame, 1]);
QPFrames = strings([nFrame, 1]);

EncoderReconstructOutputPath = 'EncoderReconstructOutput\';
if ~exist(EncoderReconstructOutputPath,'dir')
    mkdir(EncoderReconstructOutputPath)
end

if RCFlag == 1
    frameTotalBits = targetBR/frameRate;
else
    frameTotalBits = Inf;
    statistics = [];
    QPs = [];
end

actualBitSpent = frameTotalBits;

for currentFrameNum = 1:nFrame
    if rem(currentFrameNum,I_Period) == 1 || I_Period == 1
        % First frame needs to be I frame
        [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent] = intraPrediction( ...
            paddingY(:,:,currentFrameNum), blockSize, QP, VBSEnable, ...
            FMEEnable, FastME, RCFlag, 2*frameTotalBits - actualBitSpent, QPs, statistics);
        QTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        splits(currentFrameNum, 1) = splitFrame;
        QPFrames(currentFrameNum, 1) = QPFrame;
        % Update reconstructed Y-only frames with reconstructed frame
        reconstructedY(:, :, currentFrameNum) = reconstructedFrame;
        interpolateRefFrames(:,:,currentFrameNum) = interpolateFrames(reconstructedFrame);
        % Update reference frame with reconstructed frame
        referenceFrames = reconstructedFrame;
        interpolateReferenceFrames = interpolateRefFrames(:,:,currentFrameNum);
    else
        [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent] = interPrediction( ...
            referenceFrames, interpolateReferenceFrames, paddingY(:,:,currentFrameNum), ...
            blockSize, r, QP, VBSEnable, FMEEnable, FastME, RCFlag, ...
            2*frameTotalBits - actualBitSpent, QPs, statistics);
        QTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        splits(currentFrameNum, 1) = splitFrame;
        QPFrames(currentFrameNum, 1) = QPFrame;
        % Update reconstructed Y-only frames with reconstructed frame
        reconstructedY(:, :, currentFrameNum) = reconstructedFrame;
        interpolateRefFrames(:,:,currentFrameNum) = interpolateFrames(reconstructedFrame);
        % Update reference frame with reconstructed Y-only frames
        referenceFrames = updateRefFrames(reconstructedY, nRefFrames, currentFrameNum, I_Period);
        interpolateReferenceFrames = updateRefFrames(interpolateRefFrames, nRefFrames, currentFrameNum, I_Period);
    end

end

% Store data in binary format
save('QTCCoeffs.mat', 'QTCCoeffs');
save('MDiffs.mat', 'MDiffs');
save('splits.mat', 'splits');
save('QPFrames.mat', 'QPFrames');

end

function referenceFrame = updateRefFrames(reconsructedY, nRefFrames, currentFrameNum, I_Period)
    num = min(rem(currentFrameNum, I_Period), nRefFrames);
    if num == 0
        num = min(I_Period, nRefFrames);
    end
    for i=1:num
        referenceFrame(:,:,i) = reconsructedY(:,:,currentFrameNum-i+1);
    end
end
