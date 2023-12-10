function reconstructedY = encoder(yuvInputFileName, nFrame, width, height, ...
    blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, ...
    FastME, RCFlag, targetBR, frameRate, QPs, statistics, parallelMode)

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

perRowBitCount = [];
splitDecision = zeros(1, widthBlockNum * heightBlockNum);

for currentFrameNum = 1:nFrame
    % copy the RCFlag from the user-specified one, so that we can modify
    % that for this frame only
    encoderRCFlagFrame = RCFlag;
    
    if encoderRCFlagFrame >= 1
        if rem(currentFrameNum,frameRate) == 1 || frameRate == 1
            actualBitSpent = 0;
            totalBits = targetBR;
        end
        totalBits = totalBits - actualBitSpent;
        if frameRate == 1
            frameTotalBits = totalBits;
        else
            frameTotalBits = int32(totalBits / (frameRate-rem(currentFrameNum,frameRate)+1));
        end
    else
        frameTotalBits = Inf;
        statistics = [];
        QPs = [];
    end
    
    IFrame = rem(currentFrameNum,I_Period) == 1 || I_Period == 1;
    
    % first pass of multi-pass encoding
    if encoderRCFlagFrame >= 2 && ~IFrame
        % P frame, do a encoding pass with constant QP (i.e. RCFlag = 0)
        tempRCFlag = 0;
        if currentFrameNum == 1
            [tempQP, tempQPIndex] = getCurrentQP(QPs, statistics{2}, double(frameTotalBits) / double(heightBlockNum));
        else
            tempQP = round(avgQP);
            tempQPIndex = find(QPs == tempQP);
        end
        [~, ~, ~, ~, ~, actualBitSpent, perRowBitCount, ~, splitDecision] = interPrediction( ...
                referenceFrames, interpolateReferenceFrames, paddingY(:,:,currentFrameNum), ...
                blockSize, r, tempQP, VBSEnable, FMEEnable, FastME, tempRCFlag, ...
                frameTotalBits, QPs, statistics, [], zeros(1, widthBlockNum * heightBlockNum), parallelMode);
        
        actualBitSpentPerBlock = actualBitSpent / (widthBlockNum * heightBlockNum);
        if actualBitSpentPerBlock > getSceneChangeThreshold(tempQP)
            IFrame = true;
            % the prediction method changes between the two encoding passes, 
            % and hence, no other info from the first pass can be leveraged for the second pass
            encoderRCFlagFrame = 1;
        end
        
        % update statistics
        interStatistics = statistics{2};
        scaleFactor = double(actualBitSpent) / double(heightBlockNum) / double(interStatistics(tempQPIndex));
        for i=1:length(interStatistics)
           interStatistics(i) = double(interStatistics(i)) * scaleFactor;
        end
        statistics{2} = interStatistics;
    elseif encoderRCFlagFrame >= 2 && IFrame
        tempRCFlag = 0;
        if currentFrameNum == 1
            [tempQP, tempQPIndex] = getCurrentQP(QPs, statistics{1}, double(frameTotalBits) / double(heightBlockNum));
        else
            tempQP = round(avgQP);
            tempQPIndex = find(QPs == tempQP);
        end
        [~, ~, ~, ~, ~, actualBitSpent, perRowBitCount, ~, splitDecision] = intraPrediction( ...
                paddingY(:,:,currentFrameNum), blockSize, tempQP, VBSEnable, ...
                FMEEnable, FastME, tempRCFlag, frameTotalBits, QPs, statistics, [], zeros(1, widthBlockNum * heightBlockNum), parallelMode);
        
        % update statistics
        intraStatistics = statistics{1};
        scaleFactor = double(actualBitSpent) / double(heightBlockNum) / double(intraStatistics(tempQPIndex));
        for i=1:length(intraStatistics)
           intraStatistics(i) = double(intraStatistics(i)) * scaleFactor;
        end
        statistics{1} = intraStatistics;
    end
    
    if IFrame
        % First frame needs to be I frame
        [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent, ~, avgQP, ~] = intraPrediction( ...
            paddingY(:,:,currentFrameNum), blockSize, QP, VBSEnable, ...
            FMEEnable, FastME, encoderRCFlagFrame, frameTotalBits, QPs, statistics, perRowBitCount, splitDecision, parallelMode);
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
        [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent, ~, avgQP, ~] = interPrediction( ...
            referenceFrames, interpolateReferenceFrames, paddingY(:,:,currentFrameNum), ...
            blockSize, r, QP, VBSEnable, FMEEnable, FastME, encoderRCFlagFrame, ...
            frameTotalBits, QPs, statistics, perRowBitCount, splitDecision, parallelMode);
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
