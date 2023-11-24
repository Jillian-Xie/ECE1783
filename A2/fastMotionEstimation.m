function [bestMV, bestMAE, referenceBlock, residualBlock] = fastMotionEstimation(refFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, MVP)

bestMAE = Inf;
bestMV = int32([0, 0, 0]);

currentBlock = currentFrame(heightPixelIndex:heightPixelIndex+blockSize-1,widthPixelIndex:widthPixelIndex+blockSize-1);

numRefFrames = size(refFrames,3);
for indexRefFrame = 1:numRefFrames
    refFrame = refFrames(:,:,indexRefFrame);

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

% Search the (0, 0) location
if MVP(1) == 0 && MVP(2) == 0
    MAEFrame = Inf;
else
    refBlockFrame = refFrame(heightPixelIndex:heightPixelIndex+blockSize-1, widthPixelIndex:widthPixelIndex+blockSize-1);
    MAEFrame = sum(abs(int32(currentBlock) - int32(refBlockFrame)), "all") / numel(currentBlock);
    MVFrame = int32([0, 0, indexRefFrame-1]);
    residualBlockFrame = int32(currentBlock) - int32(refBlockFrame);
end
% Set the search origin to a predicted vector location and search this position
originHeightPixelIndex = heightPixelIndex + MVP(1);
originWidthPixelIndex = widthPixelIndex + MVP(2);

if checkFrameBoundary(originWidthPixelIndex, originHeightPixelIndex, blockSize, refFrame) == 1
    originalBlock = refFrame(originHeightPixelIndex:originHeightPixelIndex+blockSize-1, originWidthPixelIndex:originWidthPixelIndex+blockSize-1);
    mae = sum(abs(int32(currentBlock) - int32(originalBlock)), "all") / numel(currentBlock);
    if mae < MAEFrame
        MAEFrame = mae;
        refBlockFrame = originalBlock;
        MVFrame = int32([originHeightPixelIndex-heightPixelIndex, originWidthPixelIndex-widthPixelIndex, indexRefFrame-1]);
        residualBlockFrame = int32(currentBlock)-int32(refBlockFrame);

        % Search the four neighbouring positions to the new origin in a + shape
        while(1)
            originalBlock = refFrame(originHeightPixelIndex:originHeightPixelIndex+blockSize-1, originWidthPixelIndex:originWidthPixelIndex+blockSize-1);
            neighbours = {[originHeightPixelIndex-1, originWidthPixelIndex],...
                [originHeightPixelIndex, originWidthPixelIndex-1],...
                [originHeightPixelIndex+1, originWidthPixelIndex],...
                [originHeightPixelIndex, originWidthPixelIndex+1]};

            for neighbour = 1:length(neighbours)
                neighbourHeightPixelIndex = neighbours{neighbour}(1);
                neighbourWidthPixelIndex = neighbours{neighbour}(2);

                if checkFrameBoundary(neighbourWidthPixelIndex, neighbourHeightPixelIndex, blockSize, refFrame) == 1
                    refBlock = refFrame(neighbourHeightPixelIndex: neighbourHeightPixelIndex+blockSize-1, neighbourWidthPixelIndex:neighbourWidthPixelIndex+blockSize-1);
                    mae = sum(abs(int32(currentBlock)-int32(refBlock)), "all") / numel(currentBlock);
                    if mae < MAEFrame
                        refBlockFrame = refBlock;
                        MAEFrame = mae;
                        MVFrame = int32([neighbourHeightPixelIndex-heightPixelIndex, neighbourWidthPixelIndex-widthPixelIndex, indexRefFrame-1]);
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