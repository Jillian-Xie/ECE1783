function reconstructedY = encoder_parallelMode1(yuvInputFileName, nFrame, width, height, ...
    blockSize, QP)

[Y,~,~] = importYUV(yuvInputFileName, width, height ,nFrame);

% Padding if the width and/or height of the frame is not divisible by i
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);

% Reconstructed Y-only frames (with padding)
reconstructedY(1:size(paddingY,1),1:size(paddingY,2),1:nFrame) = paddingY;

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

for currentFrameNum = 1:nFrame
    
    tempQTCCoeffsFrame = cell(heightBlockNum, widthBlockNum);
    tempMDiffsFrame = cell(heightBlockNum, widthBlockNum); % Not used in Parallel Mode 1
    tempSplitFrame = cell(heightBlockNum, widthBlockNum);
    tempQPFrame = cell(heightBlockNum, widthBlockNum);
    tempReconstructedBlockFrame = cell(heightBlockNum, widthBlockNum);

    parfor blockIndex = 1:(widthBlockNum * heightBlockNum)
        % Calculate block coordinates from linear index
        [heightBlockIndex, widthBlockIndex] = ind2sub([heightBlockNum, widthBlockNum], blockIndex);

        % Extract the current block from the frame
        currentBlock = paddingY((heightBlockIndex-1)*blockSize+1:heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1:widthBlockIndex*blockSize, currentFrameNum);

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
end

save('QTCCoeffs.mat', 'QTCCoeffs');
save('MDiffs.mat', 'MDiffs');
save('splits.mat', 'splits');
save('QPFrames.mat', 'QPFrames');

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
