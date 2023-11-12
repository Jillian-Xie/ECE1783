function encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME)

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);

% Padding if the width and/or height of the frame is not divisible by i
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);

% the reference frame for intra- or inter-frame prediction
referenceFrames(1:size(paddingY,1),1:size(paddingY,2),1) = uint8(128); 

% Reconstructed Y-only frames (with padding)
reconsructedY(1:size(paddingY,1),1:size(paddingY,2),1:nFrame) = paddingY;

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

QTCCoeffs = strings([nFrame, widthBlockNum * heightBlockNum * 4]);
MDiffs = strings([nFrame, 1]);
splits = strings([nFrame, 1]);

% https://ieeexplore.ieee.org/document/1626308
Lambda = 0.85 * (2 ^ ((QP-12) / 3));

EncoderReconstructOutputPath = 'EncoderReconstructOutput\';
if ~exist(EncoderReconstructOutputPath,'dir')
    mkdir(EncoderReconstructOutputPath)
end

for currentFrameNum = 1:nFrame
    if rem(currentFrameNum,I_Period) == 1 || I_Period == 1
        % First frame needs to be I frame
        [QTCCoeffsFrame, MDiffsFrame, splitFrame, reconstructedFrame] = intraPrediction(paddingY(:,:,currentFrameNum), blockSize, QP, VBSEnable, FMEEnable, FastME, Lambda);
        QTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        splits(currentFrameNum, 1) = splitFrame;
        % Update reconstructed Y-only frames with reconstructed frame
        reconsructedY(:, :, currentFrameNum) = reconstructedFrame;
        % Update reference frame with reconstructed frame
        referenceFrames = reconstructedFrame;
    else
        [QTCCoeffsFrame, MDiffsFrame, splitFrame, reconstructedFrame] = interPrediction(referenceFrames, paddingY(:,:,currentFrameNum), blockSize, r, QP, VBSEnable, FMEEnable, FastME, Lambda);
        QTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        splits(currentFrameNum, 1) = splitFrame;
        % Update reconstructed Y-only frames with reconstructed frame
        reconsructedY(:, :, currentFrameNum) = reconstructedFrame;
        % Update reference frame with reconstructed Y-only frames
        referenceFrames = updateRefFrames(reconsructedY, nRefFrames, currentFrameNum, I_Period);
    end
    
    % get YOnly vedio
    YOnlyFilePath = [EncoderReconstructOutputPath, sprintf('%04d',currentFrameNum), '.yuv'];
    fid = createOrClearFile(YOnlyFilePath);
    fwrite(fid,uint8(reconstructedFrame(1:height,1:width)),'uchar');
    fclose(fid);
end

% Store data in binary format
save('QTCCoeffs.mat', 'QTCCoeffs');
save('MDiffs.mat', 'MDiffs');
save('splits.mat', 'splits');

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
