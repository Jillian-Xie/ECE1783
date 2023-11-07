function [bestMV, referenceBlock, residualBlock] = integerPixelFullSearch(refFrame, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r)

bestMAE = Inf;
bestMV = int32([0, 0, 0]);

currentBlock = currentFrame(heightPixelIndex:heightPixelIndex+blockSize-1,widthPixelIndex:widthPixelIndex+blockSize-1);

numRefFrames = size(refFrame,3);
for indexRefFrame = 1:numRefFrames
    frame = refFrame(:,:,indexRefFrame);
    for mvY = -r:r
        for mvX = -r:r
            refWidthPixelIndex = int32(int32(widthPixelIndex) + mvX);
            refHeightPixelIndex = int32(int32(heightPixelIndex) + mvY);
            if checkFrameBoundary(refWidthPixelIndex, refHeightPixelIndex, blockSize, frame) == 1
                refBlock = frame(refHeightPixelIndex:refHeightPixelIndex+blockSize-1, refWidthPixelIndex:refWidthPixelIndex+blockSize-1);
                mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
                if mae < bestMAE % Update bestMV
                    bestMAE = mae;
                    bestMV = [mvY, mvX, indexRefFrame - 1];
                    residualBlock = int32(currentBlock) - int32(refBlock);
                    referenceBlock = int32(refBlock);
                elseif mae == bestMAE % If there is still a tie, choose the block with smallest 𝑦
                    currentL1Norm = abs(mvX) + abs(mvY);
                    bestL1Norm = abs(bestMV(1)) + abs(bestMV(2));
                    if currentL1Norm < bestL1Norm
                        bestMV = [mvY, mvX, indexRefFrame - 1];
                        residualBlock = int32(currentBlock) - int32(refBlock);
                        referenceBlock = int32(refBlock);
                    elseif currentL1Norm == bestL1Norm % choose the one with the smallest 𝑥
                        if mvX < bestMV(2)
                            bestMV = [mvY, mvX, indexRefFrame - 1];
                            residualBlock = int32(currentBlock) - int32(refBlock);
                            referenceBlock = int32(refBlock);
                        elseif mvX == bestMV(2) && mvY < bestMV(1)
                            bestMV = [mvY, mvX, indexRefFrame - 1];
                            residualBlock = int32(currentBlock) - int32(refBlock);
                            referenceBlock = int32(refBlock);
                        end
                    end
                end
            end
        end
    end
end
