function [split, bestMV, referenceBlock, residualBlock] = integerPixelFullSearch(refFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r, VBSEnable, QP)

split = false;
bestMAENonSplit = Inf;
bestMVNonSplit = int32([0, 0, 0]);

bestMAESplit = Inf(1, 4);
bestMVSplit = int32(zeros(4,3));

splitSize = blockSize / 2;
bestReferenceBlockSplit = zeros(splitSize, splitSize, 4);
bestResidualBlockSplit = zeros(splitSize, splitSize, 4);

currentBlock = currentFrame(heightPixelIndex:heightPixelIndex+blockSize-1,widthPixelIndex:widthPixelIndex+blockSize-1);

numRefFrames = size(refFrames,3);
for indexRefFrame = 1:numRefFrames
    refFrame = refFrames(:,:,indexRefFrame);
    
    [MAEFrame, MVFrame, refBlockFrame, residualBlockFrame] = getBestMVInRefFrame(indexRefFrame, refFrame, currentBlock, blockSize, widthPixelIndex, heightPixelIndex, r);
    
    if MAEFrame < bestMAENonSplit
        bestMAENonSplit = MAEFrame;
        bestMVNonSplit = MVFrame;
        bestReferenceBlockNonSplit = refBlockFrame;
        bestResidualBlockNonSplit = residualBlockFrame;
    end
    
    if VBSEnable        
        % we can calculate the hypothetical pixel indexes as if the
        % blockSize is halved
        topLeftWidthPixelIndex = widthPixelIndex;
        topLeftHeightPixelIndex = heightPixelIndex;
        
        topRightWidthPixelIndex = widthPixelIndex + splitSize;
        topRightHeightPixelIndex = heightPixelIndex;
        
        bottomLeftWidthPixelIndex = widthPixelIndex;
        bottomLeftHeightPixelIndex = heightPixelIndex + splitSize;
        
        bottomRightWidthPixelIndex = widthPixelIndex + splitSize;
        bottomRightHeightPixelIndex = heightPixelIndex + splitSize;
        
        topLeftSplit = currentBlock(1:splitSize, 1:splitSize);
        [bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit] = ...
            getSplitMVByIndex(1, bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit, ...
                              indexRefFrame, refFrame, topLeftSplit, splitSize, topLeftWidthPixelIndex, topLeftHeightPixelIndex, r);
        
        topRightSplit = currentBlock(1:splitSize, splitSize+1:2*splitSize);
        [bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit] = ...
            getSplitMVByIndex(1, bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit, ...
                              indexRefFrame, refFrame, topRightSplit, splitSize, topRightWidthPixelIndex, topRightHeightPixelIndex, r);
        
        bottomLeftSplit = currentBlock(splitSize+1:2*splitSize, 1:splitSize);
        [bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit] = ...
            getSplitMVByIndex(1, bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit, ...
                              indexRefFrame, refFrame, bottomLeftSplit, splitSize, bottomLeftWidthPixelIndex, bottomLeftHeightPixelIndex, r);
        
        bottomRightSplit = currentBlock(splitSize+1:2*splitSize, splitSize+1:2*splitSize);
        [bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit] = ... 
            getSplitMVByIndex(1, bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit, ...
                              indexRefFrame, refFrame, bottomRightSplit, splitSize, bottomRightWidthPixelIndex, bottomRightHeightPixelIndex, r);
    end
end

if VBSEnable == false
    split = false;
    bestMV = bestMVNonSplit;
    referenceBlock = bestReferenceBlockNonSplit;
    residualBlock = bestResidualBlockNonSplit;
else
    SADNonSplit = bestMAENonSplit * blockSize * blockSize;
    SADSplit = sum(bestMAESplit(1, 1:numRefFrames), "all") * splitSize * splitSize;
    % https://ieeexplore.ieee.org/document/1626308
    Lambda = 0.85 * (2 ^ ((QP-12) / 3));
    
    totalBitsNonSplit = 0;
    totalBitsSplit = 0;
    
    [encodedQuantizedBlock, ~] = dctQuantizeAndEncode(bestResidualBlockNonSplit, QP, blockSize);
    totalBitsNonSplit = totalBitsNonSplit + strlength(encodedQuantizedBlock);
    
    smallBlockQP = QP - 1;
    if smallBlockQP < 0; smallBlockQP = 0; end
    for splitIndex = 1:4
        [encodedQuantizedBlock, ~] = dctQuantizeAndEncode(bestResidualBlockSplit(:, :, splitIndex), smallBlockQP, splitSize);
        totalBitsSplit = totalBitsSplit + strlength(encodedQuantizedBlock);
    end
    
    % for MVs
    totalBitsNonSplit = totalBitsNonSplit + 3;
    totalBitsSplit = totalBitsSplit + 12;
    
    JNonSplit = SADNonSplit + Lambda * totalBitsNonSplit;
    Jsplit = SADSplit + Lambda * totalBitsSplit;
    
    if Jsplit < JNonSplit
        split = true;
        bestMV = bestMVSplit;
        referenceBlock = bestReferenceBlockSplit;
        residualBlock = bestResidualBlockSplit;
    else
        split = false;
        bestMV = bestMVNonSplit;
        referenceBlock = bestReferenceBlockNonSplit;
        residualBlock = bestResidualBlockNonSplit;
    end
end
end

function [bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit] = ...
                getSplitMVByIndex(splitIndex, bestMAESplit, bestMVSplit, bestReferenceBlockSplit, bestResidualBlockSplit, ...
                                  indexRefFrame, refFrame, splitBlock, splitSize, splitWidthPixelIndex, splitHeightPixelIndex, r)
    [MAEFrame, MVFrame, refBlockFrame, residualBlockFrame] = getBestMVInRefFrame(indexRefFrame, refFrame, splitBlock, splitSize, splitWidthPixelIndex, splitHeightPixelIndex, r);
    if MAEFrame < bestMAESplit(1, splitIndex)
        bestMAESplit(1, splitIndex) = MAEFrame;
        bestMVSplit(splitIndex, :) = MVFrame;
        bestReferenceBlockSplit(:, :, splitIndex) = refBlockFrame;
        bestResidualBlockSplit(:, :, splitIndex) = residualBlockFrame;
    end
end

function [MAEFrame, MVFrame, refBlockFrame, residualBlockFrame] = getBestMVInRefFrame(indexRefFrame, refFrame, currentBlock, blockSize, widthPixelIndex, heightPixelIndex, r)
    MAEFrame = Inf;
    MVFrame = int32([0, 0, 0]);
    
    for mvY = -r:r
        for mvX = -r:r
            refWidthPixelIndex = int32(int32(widthPixelIndex) + mvX);
            refHeightPixelIndex = int32(int32(heightPixelIndex) + mvY);
            if checkFrameBoundary(refWidthPixelIndex, refHeightPixelIndex, blockSize, refFrame) == 1
                refBlock = refFrame(refHeightPixelIndex:refHeightPixelIndex+blockSize-1, refWidthPixelIndex:refWidthPixelIndex+blockSize-1);
                mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
                if mae < MAEFrame % Update bestMV
                    MAEFrame = mae;
                    MVFrame = [mvY, mvX, indexRefFrame - 1];
                    residualBlockFrame = int32(currentBlock) - int32(refBlock);
                    refBlockFrame = int32(refBlock);
                elseif mae == MAEFrame % If there is still a tie, choose the block with smallest 𝑦
                    currentL1Norm = abs(mvX) + abs(mvY);
                    bestL1Norm = abs(MVFrame(1)) + abs(MVFrame(2));
                    if currentL1Norm < bestL1Norm
                        MVFrame = [mvY, mvX, indexRefFrame - 1];
                        residualBlockFrame = int32(currentBlock) - int32(refBlock);
                        refBlockFrame = int32(refBlock);
                    elseif currentL1Norm == bestL1Norm % choose the one with the smallest 𝑥
                        if mvX < MVFrame(2)
                            MVFrame = [mvY, mvX, indexRefFrame - 1];
                            residualBlockFrame = int32(currentBlock) - int32(refBlock);
                            refBlockFrame = int32(refBlock);
                        elseif mvX == MVFrame(2) && mvY < MVFrame(1)
                            MVFrame = [mvY, mvX, indexRefFrame - 1];
                            residualBlockFrame = int32(currentBlock) - int32(refBlock);
                            refBlockFrame = int32(refBlock);
                        end
                    end
                end
            end
        end
    end
end