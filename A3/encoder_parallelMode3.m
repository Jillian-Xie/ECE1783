function reconstructedY = encoder_parallelMode3(yuvInputFileName, nFrame, width, height, ...
    blockSize, r, QP, I_Period, VBSEnable, FMEEnable, FastME)

[Y,~,~] = importYUV(yuvInputFileName, width, height ,nFrame);
Lambda = getLambda(QP);

% Padding if the width and/or height of the frame is not divisible by i
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);

% the reference frame for intra- or inter-frame prediction
referenceFrames(1:size(paddingY,1),1:size(paddingY,2),1) = int32(128);
interpolateReferenceFrames(1:2*height-1, 1:2*width-1, 1) = int32(128);

% Reconstructed Y-only frames (with padding)
original_reconstructedY(1:size(paddingY,1),1:size(paddingY,2),1:nFrame) = paddingY;

interpolateRefFrames(1:2*height-1, 1:2*width-1, nFrame) = int32(0);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

uncombinedQTCCoeffs = strings([nFrame, widthBlockNum * heightBlockNum * 4]);
uncombinedMDiffs = strings([nFrame, 1]);
uncombinedsplits = strings([nFrame, 1]);
uncombinedQPFrames = strings([nFrame, 1]);

EncoderReconstructOutputPath = 'EncoderReconstructOutput\';
if ~exist(EncoderReconstructOutputPath,'dir')
    mkdir(EncoderReconstructOutputPath)
end

spmd(2)
    if spmdIndex == 1
        for currentFrameNum = 1 : 2 : nFrame
            previousQP = 6;

            if currentFrameNum == 1
                referenceFrame = uint8(128 * ones(height, width));
            else
                referenceFrame = spmdReceive(2);
            end

            reconstructedFrame(1:height,1:width) = int32(128);
            currentFrame = paddingY(:,:,currentFrameNum);

            if rem(currentFrameNum,I_Period) == 1 || I_Period == 1
                QTCCoeffsFrame = strings(0);
                MDiffsInt = [];
                splitInt = [];
                QPInt = [0]; % encode the first bit as 0 to signify this is an I-frame

                for heightBlockIndex = 1:heightBlockNum
                    previousMode = int32(0); % assume horizontal in the beginning
                    for widthBlockIndex = 1:widthBlockNum

                        currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);

                        [verticalRefernce, horizontalReference] = getIntraPredictionReference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize);
                        [split, mode, encodedQuantizedBlock, reconstructedBlock] = intraPredictBlock( ...
                            verticalRefernce, horizontalReference, currentBlock, blockSize, QP, ...
                            previousMode, VBSEnable, FMEEnable, FastME, Lambda, 0, 0);

                        splitInt = [splitInt, split];
                        QTCCoeffsFrame = [QTCCoeffsFrame, encodedQuantizedBlock];

                        if VBSEnable && split
                            for i = 1:4
                                MDiffsInt = [MDiffsInt, xor(mode(1, i), previousMode)]; % 0 = no change, 1 = changed
                                previousMode = mode(1, i);
                            end
                        else
                            % differential encoding
                            MDiffsInt = [MDiffsInt, xor(mode, previousMode)]; % 0 = no change, 1 = changed
                            previousMode = mode;
                        end

                        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = reconstructedBlock;
                    end
                    
                    QPInt = [QPInt, QP - previousQP];
                    previousQP = QP;

                    if currentFrameNum ~= nFrame
                        spmdSend(reconstructedFrame, 2);
                    end
                end



                MDiffRLE = RLE(MDiffsInt);
                MDiffsFrame = expGolombEncoding(MDiffRLE);

                splitRLE = RLE(splitInt);
                splitFrame = expGolombEncoding(splitRLE);

                QPRLE = RLE(QPInt);
                QPFrame = expGolombEncoding(QPRLE);

                uncombinedQTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
                uncombinedMDiffs(currentFrameNum, 1) = MDiffsFrame;
                uncombinedsplits(currentFrameNum, 1) = splitFrame;
                uncombinedQPFrames(currentFrameNum, 1) = QPFrame;
                % Update reconstructed Y-only frames with reconstructed frame
                original_reconstructedY(:, :, currentFrameNum) = reconstructedFrame;
            else
                QTCCoeffsFrame = strings(0);
                MDiffsInt = [];
                splitInt = [];
                QPInt = [1]; % encode the first bit as 0 to signify this is an I-frame

                for heightBlockIndex = 1:heightBlockNum
                    previousMV = int32([0, 0, 0]);
                    for widthBlockIndex = 1:widthBlockNum
                        interpolateRefFrame = interpolateFrames(referenceFrame);
                        [split, bestMV, encodedQuantizedBlock, reconstructedBlock] = interPredictBlock( ...
                            referenceFrame, interpolateRefFrame, currentFrame, ...
                            widthBlockIndex, heightBlockIndex, r,blockSize, QP, ...
                            VBSEnable, FMEEnable, FastME, previousMV, Lambda, 0, 0);

                        splitInt = [splitInt, split];
                        QTCCoeffsFrame = [QTCCoeffsFrame, encodedQuantizedBlock];

                        if VBSEnable && split
                            for i = 1:4
                                MDiffsInt = [MDiffsInt, bestMV(i, :) - previousMV]; % 0 = no change, 1 = changed
                                previousMV = bestMV(i, :);
                            end
                        else
                            % Differential encoding
                            MDiffsInt = [MDiffsInt, bestMV - previousMV];
                            previousMV = bestMV;
                        end

                        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = reconstructedBlock;
                    end

                    QPInt = [QPInt, QP - previousQP];
                    previousQP = QP;

                    if currentFrameNum ~= nFrame
                        spmdSend(reconstructedFrame, 2);
                    end
                end

                MDiffRLE = RLE(MDiffsInt);
                MDiffsFrame = expGolombEncoding(MDiffRLE);

                splitRLE = RLE(splitInt);
                splitFrame = expGolombEncoding(splitRLE);

                QPRLE = RLE(QPInt);
                QPFrame = expGolombEncoding(QPRLE);

                uncombinedQTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
                uncombinedMDiffs(currentFrameNum, 1) = MDiffsFrame;
                uncombinedsplits(currentFrameNum, 1) = splitFrame;
                uncombinedQPFrames(currentFrameNum, 1) = QPFrame;
                % Update reconstructed Y-only frames with reconstructed frame
                original_reconstructedY(:, :, currentFrameNum) = reconstructedFrame;
            end
            if currentFrameNum ~= nFrame
                spmdSend(reconstructedFrame, 2);
                spmdSend(reconstructedFrame, 2);
            end    
        end
    elseif spmdIndex == 2
        for currentFrameNum = 2 : 2 : nFrame
            
            previousQP = 6;
            referenceFrame = spmdReceive(1);
            referenceFrame = spmdReceive(1);
            reconstructedFrame(1:height,1:width) = int32(128);
            currentFrame = paddingY(:,:,currentFrameNum);

            if rem(currentFrameNum,I_Period) == 1 || I_Period == 1

                QTCCoeffsFrame = strings(0);
                MDiffsInt = [];
                splitInt = [];
                QPInt = [0]; % encode the first bit as 0 to signify this is an I-frame

                for heightBlockIndex = 1:heightBlockNum
                    previousMode = int32(0); % assume horizontal in the beginning
                    if heightBlockIndex ~= heightBlockNum
                        referenceFrame = spmdReceive(1);
                    end
                    for widthBlockIndex = 1:widthBlockNum

                        currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);

                        [verticalRefernce, horizontalReference] = getIntraPredictionReference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize);
                        [split, mode, encodedQuantizedBlock, reconstructedBlock] = intraPredictBlock( ...
                            verticalRefernce, horizontalReference, currentBlock, blockSize, QP, ...
                            previousMode, VBSEnable, FMEEnable, FastME, Lambda, 0, 0);

                        splitInt = [splitInt, split];
                        QTCCoeffsFrame = [QTCCoeffsFrame, encodedQuantizedBlock];

                        if VBSEnable && split
                            for i = 1:4
                                MDiffsInt = [MDiffsInt, xor(mode(1, i), previousMode)]; % 0 = no change, 1 = changed
                                previousMode = mode(1, i);
                            end
                        else
                            % differential encoding
                            MDiffsInt = [MDiffsInt, xor(mode, previousMode)]; % 0 = no change, 1 = changed
                            previousMode = mode;
                        end

                        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = reconstructedBlock;
                    end
                    QPInt = [QPInt, QP - previousQP];
                    previousQP = QP;
                end

                MDiffRLE = RLE(MDiffsInt);
                MDiffsFrame = expGolombEncoding(MDiffRLE);

                splitRLE = RLE(splitInt);
                splitFrame = expGolombEncoding(splitRLE);

                QPRLE = RLE(QPInt);
                QPFrame = expGolombEncoding(QPRLE);

                uncombinedQTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
                uncombinedMDiffs(currentFrameNum, 1) = MDiffsFrame;
                uncombinedsplits(currentFrameNum, 1) = splitFrame;
                uncombinedQPFrames(currentFrameNum, 1) = QPFrame;
                % Update reconstructed Y-only frames with reconstructed frame
                original_reconstructedY(:, :, currentFrameNum) = reconstructedFrame;
            else
                QTCCoeffsFrame = strings(0);
                MDiffsInt = [];
                splitInt = [];
                QPInt = [1]; % encode the first bit as 0 to signify this is an I-frame

                for heightBlockIndex = 1:heightBlockNum
                    previousMV = int32([0, 0, 0]);
                    if heightBlockIndex ~= heightBlockNum
                        referenceFrame = spmdReceive(1);
                    end
                    for widthBlockIndex = 1:widthBlockNum
                        interpolateRefFrame = interpolateFrames(referenceFrame);
                        [split, bestMV, encodedQuantizedBlock, reconstructedBlock] = interPredictBlock( ...
                            referenceFrame, interpolateRefFrame, currentFrame, ...
                            widthBlockIndex, heightBlockIndex, r,blockSize, QP, ...
                            VBSEnable, FMEEnable, FastME, previousMV, Lambda, 0, 0);

                        splitInt = [splitInt, split];
                        QTCCoeffsFrame = [QTCCoeffsFrame, encodedQuantizedBlock];

                        if VBSEnable && split
                            for i = 1:4
                                MDiffsInt = [MDiffsInt, bestMV(i, :) - previousMV]; % 0 = no change, 1 = changed
                                previousMV = bestMV(i, :);
                            end
                        else
                            % Differential encoding
                            MDiffsInt = [MDiffsInt, bestMV - previousMV];
                            previousMV = bestMV;
                        end

                        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = reconstructedBlock;
                    end
                    QPInt = [QPInt, QP - previousQP];
                    previousQP = QP;
                end

                MDiffRLE = RLE(MDiffsInt);
                MDiffsFrame = expGolombEncoding(MDiffRLE);

                splitRLE = RLE(splitInt);
                splitFrame = expGolombEncoding(splitRLE);

                QPRLE = RLE(QPInt);
                QPFrame = expGolombEncoding(QPRLE);

                uncombinedQTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
                uncombinedMDiffs(currentFrameNum, 1) = MDiffsFrame;
                uncombinedsplits(currentFrameNum, 1) = splitFrame;
                uncombinedQPFrames(currentFrameNum, 1) = QPFrame;
                % Update reconstructed Y-only frames with reconstructed frame
                original_reconstructedY(:, :, currentFrameNum) = reconstructedFrame;
            end
            
            msg = spmdReceive(1);

            if currentFrameNum ~= nFrame
                spmdSend(reconstructedFrame, 1);
            end
        end
    end
end

QTCCoeffs = strings(nFrame, size(uncombinedQTCCoeffs{1}, 2));

% Combine the results from both workers after the SPMD block
for frameIdx = 1:nFrame
    if mod(frameIdx, 2) == 1
        QTCCoeffs(frameIdx, :) = uncombinedQTCCoeffs{1}(frameIdx, :);
    else
        QTCCoeffs(frameIdx, :) = uncombinedQTCCoeffs{2}(frameIdx, :);
    end
end

% Initialize combined variables outside the SPMD block
MDiffs = strings(nFrame, 1);
splits = strings(nFrame, 1);
QPFrames = strings(nFrame, 1);
reconstructedY = zeros(size(original_reconstructedY{1}, 1), size(original_reconstructedY{1}, 2), nFrame);

% Combine the results from both workers after the SPMD block
for frameIdx = 1:nFrame
    if mod(frameIdx, 2) == 1  % If frameIdx is odd
        MDiffs(frameIdx) = uncombinedMDiffs{1}(frameIdx, :);
        splits(frameIdx) = uncombinedsplits{1}(frameIdx, :);
        QPFrames(frameIdx) = uncombinedQPFrames{1}(frameIdx, :);
        reconstructedY(:, :, frameIdx) = original_reconstructedY{1}(:, :, frameIdx);
    else  % If frameIdx is even
        MDiffs(frameIdx) = uncombinedMDiffs{2}(frameIdx, :);
        splits(frameIdx) = uncombinedsplits{2}(frameIdx, :);
        QPFrames(frameIdx) = uncombinedQPFrames{2}(frameIdx, :);
        reconstructedY(:, :, frameIdx) = original_reconstructedY{2}(:, :, frameIdx);
    end
end

save('MDiffs.mat', 'MDiffs');
save('splits.mat', 'splits');
save('QPFrames.mat', 'QPFrames');
save('QTCCoeffs.mat', 'QTCCoeffs');

end