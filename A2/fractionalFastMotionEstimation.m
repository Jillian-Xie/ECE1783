function [bestMV, bestMAE, referenceBlock, residualBlock] = fractionalFastMotionEstimation(interpolatedRefFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, MVP)

bestMAE = Inf;
bestMV = int32([0, 0, 0]);

currentBlock = currentFrame(heightPixelIndex:heightPixelIndex+blockSize-1,widthPixelIndex:widthPixelIndex+blockSize-1);

numRefFrames = size(interpolatedRefFrames,3);
for indexRefFrame = 1:numRefFrames
    refFrame = interpolatedRefFrames(:,:,indexRefFrame);

    [MAEFrame, MVFrame, refBlockFrame, residualBlockFrame] = getBestMVInRefFrame(indexRefFrame, refFrame, currentBlock, blockSize, widthPixelIndex, heightPixelIndex, MVP);

    if MAEFrame < bestMAE
        bestMAE = MAEFrame;
        bestMV = MVFrame;
        referenceBlock = refBlockFrame;
        residualBlock = residualBlockFrame;
    end
end
end


function [MAEFrame, MVFrame, refBlockFrame, residualBlockFrame] = getBestMVInRefFrame(indexRefFrame, refFrame, currentBlock, blockSize, widthPixelIndex, heightPixelIndex, MVP)

refWidthPixelIndex = int32(2*(widthPixelIndex-1)+1);
refHeightPixelIndex = int32(2*(heightPixelIndex-1)+1);

% Search the (0, 0) location
if MVP(1) == 0 && MVP(2) == 0
    MAEFrame = Inf;
else
    refBlockFrame = refFrame(refHeightPixelIndex:2:refHeightPixelIndex+2*(blockSize-1), refWidthPixelIndex:2:refWidthPixelIndex+2*(blockSize-1));
    MAEFrame = sum(abs(int32(currentBlock) - int32(refBlockFrame)), "all") / numel(currentBlock);
    MVFrame = int32([0, 0, indexRefFrame-1]);
    residualBlockFrame = int32(currentBlock) - int32(refBlockFrame);
end

% Set the search origin to a predicted vector location and search this position
originHeightPixelIndex = refHeightPixelIndex + MVP(1);
originWidthPixelIndex = refWidthPixelIndex + MVP(2);

if checkFrameBoundary(originWidthPixelIndex, originHeightPixelIndex, 2*blockSize-1, refFrame) == 1
    originalBlock = refFrame(originHeightPixelIndex:2:originHeightPixelIndex+2*(blockSize-1), originWidthPixelIndex:2:originWidthPixelIndex+2*(blockSize-1));
    mae = sum(abs(int32(currentBlock) - int32(originalBlock)), "all") / numel(currentBlock);
    if mae < MAEFrame
        MAEFrame = mae;
        refBlockFrame = originalBlock;
        MVFrame = int32([originHeightPixelIndex-refHeightPixelIndex, originWidthPixelIndex-refWidthPixelIndex, indexRefFrame-1]);
        residualBlockFrame = int32(currentBlock)-int32(refBlockFrame);

        % Search the four neighbouring positions to the new origin in a + shape
        while(1)
            originalBlock = refFrame(originHeightPixelIndex:2:originHeightPixelIndex+2*(blockSize-1), originWidthPixelIndex:2:originWidthPixelIndex+2*(blockSize-1));
            neighbours = {[originHeightPixelIndex-1, originWidthPixelIndex],...
                [originHeightPixelIndex, originWidthPixelIndex-1],...
                [originHeightPixelIndex+1, originWidthPixelIndex],...
                [originHeightPixelIndex, originWidthPixelIndex+1]};

            for neighbour = 1:length(neighbours)
                neighbourHeightPixelIndex = neighbours{neighbour}(1);
                neighbourWidthPixelIndex = neighbours{neighbour}(2);

                if checkFrameBoundary(neighbourWidthPixelIndex, neighbourHeightPixelIndex, 2*blockSize-1, refFrame) == 1
                    refBlock = refFrame(neighbourHeightPixelIndex:2:neighbourHeightPixelIndex+2*(blockSize-1), neighbourWidthPixelIndex:2:neighbourWidthPixelIndex+2*(blockSize-1));
                    mae = sum(abs(int32(currentBlock)-int32(refBlock)), "all") / numel(currentBlock);
                    if mae < MAEFrame
                        refBlockFrame = refBlock;
                        MAEFrame = mae;
                        MVFrame = int32([neighbourHeightPixelIndex-refHeightPixelIndex, neighbourWidthPixelIndex-refWidthPixelIndex, indexRefFrame-1]);
                        residualBlockFrame = int32(currentBlock)-int32(refBlockFrame);
                        originHeightPixelIndex = neighbourHeightPixelIndex;
                        originWidthPixelIndex = neighbourWidthPixelIndex;
                    end
                end
            end

            % If the search origin gives the best match, this is the chosen search result
            if refBlockFrame == originalBlock
                break;
            end
        end
    end
end
end