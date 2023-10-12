function [bestMAE, bestMV, residualBlock] = getBestMV(refFrame, currentFrame, widthBlockIndex, heightBlockIndex,r,blockSize)
bestMAE = Inf;
bestMV = int32([0, 0]);
currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame);
residualBlock = int32(currentBlock);
for mvX = -r:r
    for mvY = -r:r
        refWidthBlockIndex = widthBlockIndex + mvX;
        refHeightBlockIndex = heightBlockIndex + mvY;
        if checkFrameBoundary(refWidthBlockIndex, refHeightBlockIndex, blockSize, refFrame) == 1
            refBlock = getBlockContent(refWidthBlockIndex, refHeightBlockIndex, blockSize, refFrame);
            mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
            if mae < bestMAE
                bestMAE = mae;
                bestMV = [mvX, mvY];
                residualBlock = int32(currentBlock) - int32(refBlock);
            elseif mae == bestMAE
                currentL1Norm = abs(mvX) + abs(mvY);
                bestL1Norm = abs(bestMV(1)) + abs(bestMV(2));
                if currentL1Norm < bestL1Norm
                    bestMV = [mvX, mvY];
                    residualBlock = int32(currentBlock) - int32(refBlock);
                elseif currentL1Norm == bestL1Norm
                    if mvY < bestMV(2)
                        bestMV = [mvX, mvY];
                        residualBlock = int32(currentBlock) - int32(refBlock);
                    elseif mvY == bestMV(2) && mvX < bestMV(1)
                        bestMV = [mvX, mvY];
                        residualBlock = int32(currentBlock) - int32(refBlock);
                    end
                end
            end
        end
    end
end