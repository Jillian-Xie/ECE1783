function [bestMV, bestMAE, referenceBlock, residualBlock] = fractionalPixelFullSearch(interpolatedRefFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r)
    bestMAE = Inf;
    bestMV = int32([0, 0, 0]);

    currentBlock = currentFrame(heightPixelIndex:heightPixelIndex+blockSize-1, widthPixelIndex:widthPixelIndex+blockSize-1);

    numRefFrames = size(interpolatedRefFrames, 3);
    for indexRefFrame = 1:numRefFrames
        refFrame = interpolatedRefFrames(:,:,indexRefFrame);
        
        % Iterate through all fractional positions within the search range
        for mvY = -2*r:2*r
            for mvX = -2*r:2*r
                refWidthPixelIndex = int32(widthPixelIndex + mvX);
                refHeightPixelIndex = int32(heightPixelIndex + mvY);

                if checkFrameBoundary(refWidthPixelIndex, refHeightPixelIndex, blockSize, refFrame)
                    refBlock = refFrame(refHeightPixelIndex:refHeightPixelIndex+blockSize-1, refWidthPixelIndex:refWidthPixelIndex+blockSize-1);
                    mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);

                    if mae < bestMAE
                        bestMAE = mae;
                        bestMV = [mvY, mvX, indexRefFrame - 1];
                        referenceBlock = refBlock;
                        residualBlock = int32(currentBlock) - int32(refBlock);
                    end
                end
            end
        end
    end
end

