function [split, mode, encodedQuantizedBlock, reconstructedBlock] = intraPredictBlock(verticalReference, horizontalReference, currentBlock, blockSize, QP, VBSEnable, FMEEnable, FastME, Lambda)

% return values: 
%     split: boolean indicating whether we split this block 
%     mode: when split==false, mode is an integer. When split==true,
%         mode is a matrix of integers of shape 1*4
%     encodedQuantizedBlock: when split==false, encodedQuantizedBlock is a string array. When split==true,
%         encodedQuantizedBlock is matrix of string array of shape 1*4
%     reconstructedBlock: of shape blockSize * blockSize

VPredictionBlockNonSplit = zeros(blockSize, blockSize);
HPredictionBlockNonSplit = zeros(blockSize, blockSize);

split = false;
splitSize = blockSize / 2;

VPredictionBlockSplit = zeros(splitSize, splitSize, 4);
HPredictionBlockSplit = zeros(splitSize, splitSize, 4);
predictedBlockSplit = zeros(splitSize, splitSize, 4);
residualBlockSplit = zeros(splitSize, splitSize, 4);
modesSplit = zeros(1,4);
reconstructedBlock = int32(zeros(blockSize, blockSize));
            
for i=1:blockSize
    HPredictionBlockNonSplit(:, i) = horizontalReference;
    VPredictionBlockNonSplit(i, :) = verticalReference;
end

SAD_h=abs(sum(int32(HPredictionBlockNonSplit),'all') - sum(int32(currentBlock),'all'));
SAD_v=abs(sum(int32(VPredictionBlockNonSplit),'all') - sum(int32(currentBlock),'all'));

if(SAD_h > SAD_v) % decide mode by SAD
    SADNonSplit = SAD_v;
    modeNonSplit = int32(0);
    predictedBlockNonSplit = VPredictionBlockNonSplit;
else
    SADNonSplit = SAD_h;
    modeNonSplit = int32(1);
    predictedBlockNonSplit = HPredictionBlockNonSplit;
end

residualBlockNonSplit = int32(currentBlock) - int32(predictedBlockNonSplit);
[encodedQuantizedBlockNonSplit, quantizedBlockNonSplit] = dctQuantizeAndEncode(residualBlockNonSplit, QP, blockSize);
rescaledBlockNonSplit = rescaling(quantizedBlockNonSplit, QP);
approximatedResidualBlockNonSplit = idct2(rescaledBlockNonSplit);
reconstructedBlockNonSplit = int32(approximatedResidualBlockNonSplit) + int32(predictedBlockNonSplit);

reconstructedBlockSplit = int32(zeros(blockSize, blockSize));

if VBSEnable == false
    split = false;
    mode = modeNonSplit;
    encodedQuantizedBlock = encodedQuantizedBlockNonSplit;
    reconstructedBlock = reconstructedBlockNonSplit;
else
    encodedQuantizedBlockSplit = strings(1, 4);
    quantizedBlockSplit = zeros(splitSize, splitSize, 4);
    
    smallBlockQP = QP - 1;
    if smallBlockQP < 0
        smallBlockQP = 0; 
    end
    
    % top left
    topLeftSplit = currentBlock(1:splitSize, 1:splitSize);
    for i = 1:splitSize
        HPredictionBlockSplit(:, i, 1) = horizontalReference(1:splitSize, 1);
        VPredictionBlockSplit(i, :, 1) = verticalReference(1, 1:splitSize); 
    end
    SAD_h=abs(sum(int32(HPredictionBlockSplit(:, :, 1)),'all') - sum(int32(topLeftSplit),'all'));
    SAD_v=abs(sum(int32(VPredictionBlockSplit(:, :, 1)),'all') - sum(int32(topLeftSplit),'all'));
    if(SAD_h > SAD_v) % decide mode by SAD
        SADTopLeft = SAD_v;
        modesSplit(1,1) = int32(0);
        predictedBlockSplit(:, :, 1) = VPredictionBlockSplit(:, :, 1);
        residualBlockSplit(:, :, 1) = int32(topLeftSplit) - int32(predictedBlockSplit(:, :, 1));
    else
        SADTopLeft = SAD_h;
        modesSplit(1,1) = int32(1);
        predictedBlockSplit(:, :, 1) = HPredictionBlockSplit(:, :, 1);
        residualBlockSplit(:, :, 1) = int32(topLeftSplit) - int32(predictedBlockSplit(:, :, 1));
    end
    [encodedQuantizedBlockSplit(1, 1), quantizedBlockSplit(:, :, 1)] = ...
            dctQuantizeAndEncode(residualBlockSplit(:, :, 1), smallBlockQP, splitSize);
    rescaledBlock = rescaling(quantizedBlockSplit(:, :, 1), smallBlockQP);
    approximatedResidualBlock = idct2(rescaledBlock);
    reconstructedBlockSplit(1:splitSize, 1:splitSize) = int32(approximatedResidualBlock) + int32(predictedBlockSplit(:, : ,1));
    
    % top right
    topRightSplit = currentBlock(1:splitSize, splitSize+1:2*splitSize);
    for i = 1:splitSize
        HPredictionBlockSplit(:, i, 2) = reconstructedBlockSplit(1:splitSize, splitSize); % right-most column of the previous block
        VPredictionBlockSplit(i, :, 2) = verticalReference(1, splitSize+1:2*splitSize); 
    end
    SAD_h=abs(sum(int32(HPredictionBlockSplit(:, :, 2)),'all') - sum(int32(topRightSplit),'all'));
    SAD_v=abs(sum(int32(VPredictionBlockSplit(:, :, 2)),'all') - sum(int32(topRightSplit),'all'));
    if(SAD_h > SAD_v) % decide mode by SAD
        SADTopRight = SAD_v;
        modesSplit(1,2) = int32(0);
        predictedBlockSplit(:, :, 2) = VPredictionBlockSplit(:, :, 2);
        residualBlockSplit(:, :, 2) = int32(topRightSplit) - int32(predictedBlockSplit(:, :, 2));
    else
        SADTopRight = SAD_h;
        modesSplit(1,2) = int32(1);
        predictedBlockSplit(:, :, 2) = HPredictionBlockSplit(:, :, 2);
        residualBlockSplit(:, :, 2) = int32(topRightSplit) - int32(predictedBlockSplit(:, :, 2));
    end
    [encodedQuantizedBlockSplit(1, 2), quantizedBlockSplit(:, :, 2)] = ...
        dctQuantizeAndEncode(residualBlockSplit(:, :, 2), smallBlockQP, splitSize);
    rescaledBlock = rescaling(quantizedBlockSplit(:, :, 2), smallBlockQP);
    approximatedResidualBlock = idct2(rescaledBlock);
    reconstructedBlockSplit(1:splitSize, splitSize+1:2*splitSize) = int32(approximatedResidualBlock) + int32(predictedBlockSplit(:, : ,2));
    
    % bottom left
    bottomLeftSplit = currentBlock(splitSize+1:2*splitSize, 1:splitSize);
    for i = 1:splitSize
        HPredictionBlockSplit(:, i, 3) = horizontalReference(splitSize+1:2*splitSize, 1);
        VPredictionBlockSplit(i, :, 3) = reconstructedBlockSplit(splitSize, 1:splitSize); % bottom-most column of the top block
    end
    SAD_h=abs(sum(int32(HPredictionBlockSplit(:, :, 3)),'all') - sum(int32(bottomLeftSplit),'all'));
    SAD_v=abs(sum(int32(VPredictionBlockSplit(:, :, 3)),'all') - sum(int32(bottomLeftSplit),'all'));
    if(SAD_h > SAD_v) % decide mode by SAD
        SADBottomLeft = SAD_v;
        modesSplit(1,3) = int32(0);
        predictedBlockSplit(:, :, 3) = VPredictionBlockSplit(:, :, 3);
        residualBlockSplit(:, :, 3) = int32(bottomLeftSplit) - int32(predictedBlockSplit(:, :, 3));
    else
        SADBottomLeft = SAD_h;
        modesSplit(1,3) = int32(1);
        predictedBlockSplit(:, :, 3) = HPredictionBlockSplit(:, :, 3);
        residualBlockSplit(:, :, 3) = int32(bottomLeftSplit) - int32(predictedBlockSplit(:, :, 3));
    end
    [encodedQuantizedBlockSplit(1, 3), quantizedBlockSplit(:, :, 3)] = ...
        dctQuantizeAndEncode(residualBlockSplit(:, :, 3), smallBlockQP, splitSize);
    rescaledBlock = rescaling(quantizedBlockSplit(:, :, 3), smallBlockQP);
    approximatedResidualBlock = idct2(rescaledBlock);
    reconstructedBlockSplit(splitSize+1:2*splitSize, 1:splitSize) = int32(approximatedResidualBlock) + int32(predictedBlockSplit(:, : ,3));
    
    % bottom right
    bottomRightSplit = currentBlock(splitSize+1:2*splitSize, splitSize+1:2*splitSize);
    for i = 1:splitSize
        HPredictionBlockSplit(:, i, 4) = reconstructedBlockSplit(splitSize+1:2*splitSize, splitSize); 
        VPredictionBlockSplit(i, :, 4) = reconstructedBlockSplit(splitSize, splitSize+1:2*splitSize); % bottom-most column of the top block
    end
    SAD_h=abs(sum(int32(HPredictionBlockSplit(:, :, 4)),'all') - sum(int32(bottomRightSplit),'all'));
    SAD_v=abs(sum(int32(VPredictionBlockSplit(:, :, 4)),'all') - sum(int32(bottomRightSplit),'all'));
    if(SAD_h > SAD_v) % decide mode by SAD
        SADBottomRight = SAD_v;
        modesSplit(1,4) = int32(0);
        predictedBlockSplit(:, :, 4) = VPredictionBlockSplit(:, :, 4);
        residualBlockSplit(:, :, 4) = int32(bottomRightSplit) - int32(predictedBlockSplit(:, :, 4));
    else
        SADBottomRight = SAD_h;
        modesSplit(1,4) = int32(1);
        predictedBlockSplit(:, :, 4) = HPredictionBlockSplit(:, :, 4);
        residualBlockSplit(:, :, 4) = int32(bottomRightSplit) - int32(predictedBlockSplit(:, :, 4));
    end
    [encodedQuantizedBlockSplit(1, 4), quantizedBlockSplit(:, :, 4)] = ...
        dctQuantizeAndEncode(residualBlockSplit(:, :, 4), smallBlockQP, splitSize);
    rescaledBlock = rescaling(quantizedBlockSplit(:, :, 4), smallBlockQP);
    approximatedResidualBlock = idct2(rescaledBlock);
    reconstructedBlockSplit(splitSize+1:2*splitSize, splitSize+1:2*splitSize) = int32(approximatedResidualBlock) + int32(predictedBlockSplit(:, : ,4));
    
    SADSplit = SADTopLeft + SADTopRight + SADBottomLeft + SADBottomRight;

    totalBitsNonSplit = 0;
    totalBitsSplit = 0;
    
    for splitIndex = 1:4
        totalBitsSplit = totalBitsSplit + strlength(encodedQuantizedBlockSplit(1, splitIndex));
    end
    
    totalBitsNonSplit = totalBitsNonSplit + strlength(encodedQuantizedBlockNonSplit);
    
    % for modes
    totalBitsNonSplit = totalBitsNonSplit + 1;
    totalBitsSplit = totalBitsSplit + strlength(expGolombEncoding(RLE(modesSplit)));
    
    JNonSplit = SADNonSplit + Lambda * totalBitsNonSplit;
    Jsplit = SADSplit + Lambda * totalBitsSplit;
    
    if Jsplit < JNonSplit
        split = true;
        mode = modesSplit;
        encodedQuantizedBlock = encodedQuantizedBlockSplit;
        reconstructedBlock = reconstructedBlockSplit;
    else
        split = false;
        mode = modeNonSplit;
        encodedQuantizedBlock = encodedQuantizedBlockNonSplit;
        reconstructedBlock = reconstructedBlockNonSplit;
    end
end














