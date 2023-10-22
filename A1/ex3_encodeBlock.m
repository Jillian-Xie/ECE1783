function [bestMAE, bestMV, approximatedResidualBlock, reconstructedBlock] = encodeBlock(refFrame, currentFrame, widthBlockIndex, heightBlockIndex,r,blockSize,n)
bestMAE = Inf;
bestMV = int32([0, 0]);
currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);
residualBlock = int32(currentBlock);
referenceBlock(1:blockSize,1:blockSize) = int32(128);
for mvX = -r:r
    for mvY = -r:r
        refWidthPixelIndex = int32((widthBlockIndex-1)*blockSize + 1 + mvX);
        refHeightPixelIndex = int32((heightBlockIndex-1)*blockSize + 1 + mvY);
        if checkFrameBoundary(refWidthPixelIndex, refHeightPixelIndex, blockSize, refFrame) == 1
            refBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, refFrame, mvX, mvY);
            mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
            if mae < bestMAE
                bestMAE = mae;
                bestMV = [mvX, mvY];
                residualBlock = int32(currentBlock) - int32(refBlock);
                referenceBlock = int32(refBlock);
            elseif mae == bestMAE
                currentL1Norm = abs(mvX) + abs(mvY);
                bestL1Norm = abs(bestMV(1)) + abs(bestMV(2));
                if currentL1Norm < bestL1Norm
                    bestMV = [mvX, mvY];
                    residualBlock = int32(currentBlock) - int32(refBlock);
                    referenceBlock = int32(refBlock);
                elseif currentL1Norm == bestL1Norm
                    if mvY < bestMV(2)
                        bestMV = [mvX, mvY];
                        residualBlock = int32(currentBlock) - int32(refBlock);
                        referenceBlock = int32(refBlock);
                    elseif mvY == bestMV(2) && mvX < bestMV(1)
                        bestMV = [mvX, mvY];
                        residualBlock = int32(currentBlock) - int32(refBlock);
                        referenceBlock = int32(refBlock);
                    end
                end
            end
        end
    end
end
approximatedResidualBlock = round(residualBlock / (2^n)) * (2^n);
reconstructedBlock = int32(approximatedResidualBlock) + int32(referenceBlock);