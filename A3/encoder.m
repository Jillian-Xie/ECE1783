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
    avgQP = QP;
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

    if parallelMode == 1
        % Parallel processing for each block (Parallel Mode 1)
        % Initialize cell arrays for storing parallel processing results
        tempQTCCoeffsFrame = cell(heightBlockNum, widthBlockNum);
        tempMDiffsFrame = cell(heightBlockNum, widthBlockNum); % Not used in Parallel Mode 1
        tempSplitFrame = cell(heightBlockNum, widthBlockNum);
        tempQPFrame = cell(heightBlockNum, widthBlockNum);
        tempReconstructedBlockFrame = cell(heightBlockNum, widthBlockNum);

        parfor blockIndex = 1:(widthBlockNum * heightBlockNum)
            % Calculate block coordinates from linear index
            [heightBlockIndex, widthBlockIndex] = ind2sub([heightBlockNum, widthBlockNum], blockIndex);

            % Extract the current block from the frame
            currentBlock = paddingY((heightBlockIndex-1)*blockSize+1:heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1:widthBlockIndex*blockSize);

            % Perform DCT and quantization on the current block
            transformedBlock = dct2(currentBlock - 128);
            quantizedBlock = quantize(transformedBlock, QP);

            % Encode the quantized block
            scanned = scanBlock(quantizedBlock, blockSize);
            encodedRLE = RLE(scanned);
            encodedQuantizedBlock = expGolombEncoding(encodedRLE);

            % Reconstruct the block for the decoded frame (Inverse Quantization and Inverse DCT)
            rescaledBlock = rescaling(quantizedBlock, QP);
            reconstructedBlock = idct2(rescaledBlock)+128;

            % Store results in temporary cell arrays
            tempQTCCoeffsFrame{blockIndex} = encodedQuantizedBlock;
            tempMDiffsFrame{blockIndex} = zeros(1, size(encodedQuantizedBlock, 2)); % Set MDiffs to zeros
            tempSplitFrame{blockIndex} = '0';
            tempQPFrame{blockIndex} = QP;
            tempReconstructedBlockFrame{blockIndex} = reconstructedBlock;
        end

        % Assign results from temporary cell arrays to main variables after parfor loop
        for blockIndex = 1:(widthBlockNum * heightBlockNum)
            [heightBlockIndex, widthBlockIndex] = ind2sub([heightBlockNum, widthBlockNum], blockIndex);
            QTCCoeffsFrame{heightBlockIndex, widthBlockIndex} = tempQTCCoeffsFrame{blockIndex};
            
            MDiffsFrame{heightBlockIndex, widthBlockIndex} = tempMDiffsFrame{blockIndex}; % Now filled with zeros
            splitFrame{heightBlockIndex, widthBlockIndex} = tempSplitFrame{blockIndex};
            QPFrame{heightBlockIndex, widthBlockIndex} = tempQPFrame{blockIndex};
            reconstructedBlockFrame{heightBlockIndex, widthBlockIndex} = tempReconstructedBlockFrame{blockIndex};
        end

        % Combine the results from each block
        reconstructedY(:, :, currentFrameNum) = combineBlocks(reconstructedBlockFrame);
        for ii = 1:heightBlockNum
            for jj = 1:widthBlockNum
                QTCCoeffs(currentFrameNum, (ii-1)*(widthBlockNum)+jj) = QTCCoeffsFrame{ii, jj};
            end
        end
        % Update MDiffs and splits for the current frame
        numBlocks = widthBlockNum * heightBlockNum;
        MDiffs(currentFrameNum, 1:numBlocks) = zeros(1, numBlocks);
        splits(currentFrameNum, 1:numBlocks) = '0';

        % Flatten QPFrame and assign to QPFrames
        flattenedQP = [1, ones(1,heightBlockNum)*QP];
        flattenedQP = expGolombEncoding(RLE(flattenedQP));
        QPFrames(currentFrameNum, 1) = flattenedQP;

    elseif parallelMode == 3
        spmd(2) % Split the code into 2 parallel sections
            if labindex == 1
                framesToEncode = 1:2:nFrame; % Frames for thread 1
            else
                framesToEncode = 2:2:nFrame; % Frames for thread 2
            end

            for currentFrameNum = framesToEncode
                % Determine if the current frame is an I-frame
                IFrame = rem(currentFrameNum, I_Period) == 1 || I_Period == 1;

                if IFrame
                    [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent, ~, avgQP, ~] = intraPrediction( ...
                        paddingY(:,:,currentFrameNum), blockSize, QP, VBSEnable, ...
                        FMEEnable, FastME, encoderRCFlagFrame, frameTotalBits, QPs, statistics, [], zeros(1, heightBlockNum*widthBlockNum));
                
                else
                    [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent, ~, avgQP, ~] = interPrediction( ...
                        referenceFrames, interpolateReferenceFrames, paddingY(:,:,currentFrameNum), ...
                        blockSize, r, QP, VBSEnable, FMEEnable, FastME, encoderRCFlagFrame, ...
                        frameTotalBits, QPs, statistics, [], zeros(1, heightBlockNum*widthBlockNum));
                end

                % Update the reconstructed frames
                reconstructedY(:, :, currentFrameNum) = reconstructedFrame;

                % Synchronization and dependency handling
                if labindex == 1 && currentFrameNum < nFrame
                    % Thread 1 sends its last two rows to Thread 2
                    lastTwoRows = reconstructedY(end-2*blockSize+1:end, :, currentFrameNum);
                    labSend(lastTwoRows, 2);
                elseif labindex == 2 && currentFrameNum > 1
                    % Thread 2 receives the last two rows from Thread 1
                    lastTwoRows = labReceive(1);
                    % Update the reference frame in Thread 2 with these rows
                    referenceFrames = updateReferenceFramesForParallel(referenceFrames, lastTwoRows, blockSize);
                end

                QTCCoeffs(currentFrameNum, 1:size(QTCCoeffsFrame, 2)) = QTCCoeffsFrame;
                MDiffs(currentFrameNum, 1) = MDiffsFrame;
                splits(currentFrameNum, 1) = splitFrame;
                QPFrames(currentFrameNum, 1) = QPFrame;
            end
        end

    else
    % Original non-parallel processing
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

end
rgbOutputPath = 'EncoderReconstructOutput/'
plotRGB(reconstructedY, nFrame, rgbOutputPath)
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

function combinedFrame = combineBlocks(reconstructedBlockFrame)
    heightBlockNum = size(reconstructedBlockFrame, 1);
    widthBlockNum = size(reconstructedBlockFrame, 2);
    blockSize = size(reconstructedBlockFrame{1, 1}, 1);
    
    combinedFrame = zeros(heightBlockNum * blockSize, widthBlockNum * blockSize);
    for i = 1:heightBlockNum
        for j = 1:widthBlockNum
            block = reconstructedBlockFrame{i, j};
            combinedFrame((i-1)*blockSize+1:i*blockSize, (j-1)*blockSize+1:j*blockSize) = block;
        end
    end
end

function plotRGB(Y, nFrame, rgbOutputPath)
height = size(Y,1);
width = size(Y,2);
R = Y;
G = Y;
B = Y;

for i=1:nFrame
        im(:,:,1)=R(:,:,i);
        im(:,:,2)=G(:,:,i);
        im(:,:,3)=B(:,:,i);
        imwrite(uint8(im),[rgbOutputPath, sprintf('%04d',i), '.png']);
end
end

function referenceFrames = updateReferenceFramesForParallel(referenceFrames, lastTwoRows, blockSize)
    % Update the first reference frame with the last two rows from the previous frame

    % Check if the referenceFrames array is empty
    if isempty(referenceFrames)
        error('Reference frames array is empty.');
    end

    % Extract the size of the reference frames
    [refHeight, refWidth, ~] = size(referenceFrames);

    % Validate the size of the lastTwoRows
    [rows, cols, ~] = size(lastTwoRows);
    if rows ~= 2*blockSize || cols ~= refWidth
        error('Size of the last two rows does not match the expected dimensions.');
    end

    % Update the first reference frame
    % The top 2*blockSize rows are replaced with the lastTwoRows from the previous frame
    referenceFrames(1:2*blockSize, :, 1) = lastTwoRows;

    % For the remaining rows in the first reference frame, shift them up by 2*blockSize
    if refHeight > 2*blockSize
        referenceFrames(2*blockSize+1:end, :, 1) = referenceFrames(1:end-2*blockSize, :, 1);
    end
end
