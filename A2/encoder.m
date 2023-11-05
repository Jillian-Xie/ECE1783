function encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME)

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);

% Padding if the width and/or height of the frame is not divisible by i
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);

% the reference frame for intra- or inter-frame prediction
referenceFrame(1:size(paddingY,1),1:size(paddingY,2),1) = uint8(128); 

% Reconstructed Y-only frames (with padding)
reconsructedY(1:size(paddingY,1),1:size(paddingY,2),1:nFrame) = paddingY;

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

QTCCoeffs = strings([nFrame, widthBlockNum * heightBlockNum]);
MDiffs = strings([nFrame, 1]);

for currentFrameNum = 1:nFrame
    if rem(currentFrameNum,I_Period) == 1 || I_Period == 1
        % First frame needs to be I frame
        [QTCCoeffsFrame, MDiffsFrame, reconstructedFrame] = intraPrediction(paddingY(:,:,currentFrameNum), blockSize, QP, VBSEnable, FMEEnable, FastME);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        % Update reconstructed Y-only frames with reconstructed frame
        reconsructedY(:, :, currentFrameNum) = reconstructedFrame;
        % Update reference frame with reconstructed frame
        referenceFrame = reconstructedFrame;
    else
        [QTCCoeffsFrame, MDiffsFrame, reconstructedFrame] = interPrediction(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, QP, VBSEnable, FMEEnable, FastME);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        % Update reconstructed Y-only frames with reconstructed frame
        reconsructedY(:, :, currentFrameNum) = reconstructedFrame;
        % Update reference frame with reconstructed Y-only frames
        referenceFrame = updateRefFrames(reconsructedY, nRefFrames, currentFrameNum, I_Period);
    end
end

% Store data in binary format
save('QTCCoeffs.mat', 'QTCCoeffs');
save('MDiffs.mat', 'MDiffs');

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
