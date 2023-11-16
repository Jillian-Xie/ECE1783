function [bestMV, bestMAE, referenceBlock, residualBlock] = fractionalPixelFullSearch(interpolatedRefFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r)
bestMAE = Inf;
bestMV = int32([0, 0, 0]);

currentBlock = currentFrame(heightPixelIndex:heightPixelIndex+blockSize-1,widthPixelIndex:widthPixelIndex+blockSize-1);

numRefFrames = size(interpolatedRefFrames,3);
for indexRefFrame = 1:numRefFrames
    refFrame = interpolatedRefFrames(:,:,indexRefFrame);

    [MAEFrame, MVFrame, refBlockFrame, residualBlockFrame] = getBestMVInRefFrame(indexRefFrame, refFrame, currentBlock, blockSize, widthPixelIndex, heightPixelIndex, r);

    if MAEFrame < bestMAE
        bestMAE = MAEFrame;
        bestMV = MVFrame;
        referenceBlock = refBlockFrame;
        residualBlock = residualBlockFrame;
    end
end
end

function [MAEFrame, MVFrame, refBlockFrame, residualBlockFrame] = getBestMVInRefFrame(indexRefFrame, refFrame, currentBlock, blockSize, widthPixelIndex, heightPixelIndex, r)
    MAEFrame = Inf;
    MVFrame = int32([0, 0, 0]);
    
    for mvY = -2*r:2*r
        for mvX = -2*r:2*r
            refWidthPixelIndex = int32(int32(2*(widthPixelIndex-1)+1) + mvX);
            refHeightPixelIndex = int32(int32(2*(heightPixelIndex-1)+1) + mvY);
            if checkFrameBoundary(refWidthPixelIndex, refHeightPixelIndex, 2*blockSize-1, refFrame) == 1
                refBlock = refFrame(refHeightPixelIndex:2:refHeightPixelIndex+2*(blockSize-1), refWidthPixelIndex:2:refWidthPixelIndex+2*(blockSize-1));
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

