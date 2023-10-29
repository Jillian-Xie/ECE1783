function [bestMAE, bestMV, approximatedResidualBlock, reconstructedBlock, referenceBlock] = ex3_encodeBlock(refFrame, currentFrame, widthBlockIndex, heightBlockIndex, r, blockSize, n)
bestMAE = Inf;
bestMV = int32([0, 0]);
currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);
residualBlock = int32(currentBlock);
% assume reference is gray at first
referenceBlock(1:blockSize,1:blockSize) = int32(128);
for mvX = -r:r
    for mvY = -r:r
        % search +- r pixels
        refWidthPixelIndex = int32((int32(widthBlockIndex)-1)*blockSize + 1 + mvX);
        refHeightPixelIndex = int32((int32(heightBlockIndex)-1)*blockSize + 1 + mvY);
        % we don't need to continue if the reference block we are looking 
        % for is outside of the frame
        if checkFrameBoundary(refWidthPixelIndex, refHeightPixelIndex, blockSize, refFrame) == 1
            refBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, refFrame, mvX, mvY);
            mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
            
            if mae < bestMAE
                % always take the smaller MAE
                bestMAE = mae;
                bestMV = [mvX, mvY];
                residualBlock = int32(currentBlock) - int32(refBlock);
                referenceBlock = int32(refBlock);
            elseif mae == bestMAE
                % in case of equality, check the smallest L1 norm
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
% round the residual block to the nearest multiple of 2^n
approximatedResidualBlock = round(residualBlock / (2^n)) * (2^n);
% reconstruct the same way as the decoder
reconstructedBlock = int32(approximatedResidualBlock) + int32(referenceBlock);