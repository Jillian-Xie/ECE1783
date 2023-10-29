function [bestMV, quantizedBlock, reconstructedBlock] = interPredictBlock(refFrame, currentFrame, widthBlockIndex, heightBlockIndex,r,blockSize, QP)
bestMAE = Inf;
bestMV = int32([0, 0]);
currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);
residualBlock = int32(currentBlock);
% assume reference is gray at first
referenceBlock(1:blockSize,1:blockSize) = int32(128);
for mvX = -r:r
    for mvY = -r:r
        refWidthPixelIndex = int32((int32(widthBlockIndex)-1)*blockSize + 1 + mvX);
        refHeightPixelIndex = int32((int32(heightBlockIndex)-1)*blockSize + 1 + mvY);
        if checkFrameBoundary(refWidthPixelIndex, refHeightPixelIndex, blockSize, refFrame) == 1
            refBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, refFrame, mvX, mvY);
            mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
            if mae < bestMAE % Update bestMV
                bestMAE = mae;
                bestMV = [mvX, mvY];
                residualBlock = int32(currentBlock) - int32(refBlock);
                referenceBlock = int32(refBlock);
            elseif mae == bestMAE % If there is still a tie, choose the block with smallest 𝑦
                currentL1Norm = abs(mvX) + abs(mvY);
                bestL1Norm = abs(bestMV(1)) + abs(bestMV(2));
                if currentL1Norm < bestL1Norm
                    bestMV = [mvX, mvY];
                    residualBlock = int32(currentBlock) - int32(refBlock);
                    referenceBlock = int32(refBlock);
                elseif currentL1Norm == bestL1Norm % choose the one with the smallest 𝑥
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
bestMV = int32(bestMV);
transformedBlock = dct2(residualBlock);
quantizedBlock = quantize(transformedBlock, QP);
rescaledBlock = rescaling(quantizedBlock, QP);

approximatedResidualBlock = idct2(rescaledBlock);
reconstructedBlock = int32(approximatedResidualBlock) + int32(referenceBlock);