function ex4_encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period)

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);

% Padding if the width and/or height of the frame is not divisible by i
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);

% the reference frame for intra- or inter-frame prediction
referenceFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128); 

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

QTCCoeffs = strings([nFrame, widthBlockNum * heightBlockNum]);
MDiffs = strings([nFrame, 1]);

for currentFrameNum = 1:nFrame
    if rem(currentFrameNum,I_Period) == 1 || I_Period == 1
        % First frame needs to be I frame
        [QTCCoeffsFrame, MDiffsFrame, reconstructedFrame] = intraPrediction(paddingY(:,:,currentFrameNum), blockSize, QP);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        % Update reference frame with reconstructed frame
        referenceFrame = reconstructedFrame;
    else
        [QTCCoeffsFrame, MDiffsFrame, reconstructedFrame] = interPrediction(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, QP);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        % Update reference frame with reconstructed frame
        referenceFrame = reconstructedFrame;
    end
end

% Store data in binary format
save('QTCCoeffs.mat', 'QTCCoeffs');
save('MDiffs.mat', 'MDiffs');

