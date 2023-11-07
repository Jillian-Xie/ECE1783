function [bestMV, referenceBlock, residualBlock] = fastMotionEstimation(refFrame, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, MVP)

bestMAE = Inf;
bestMV = int32([0, 0, 0]);

currentBlock = currentFrame(int32(heightPixelIndex):int32(heightPixelIndex)+blockSize-1,int32(widthPixelIndex):int32(widthPixelIndex)+blockSize-1);

numRefFrames = size(refFrame,3);
for indexRefFrame = 1:numRefFrames
    frame = refFrame(:,:,indexRefFrame);
    if checkFrameBoundary(int32(widthPixelIndex)+MVP(2), int32(heightPixelIndex)+MVP(1), blockSize, frame) == 1
        tmpHeightPixelIndex = int32(heightPixelIndex)+MVP(1);
        tmpWidthPixelIndex = int32(widthPixelIndex)+MVP(2);
        tmpBlock = frame(originHeightPixelIndex:originHeightPixelIndex+blockSize-1, originWidthPixelIndex:originWidthPixelIndex+blockSize-1);
        tmpBlock = Inf(blockSize, blockSize);
        tmpHeightPixelIndex = -1;
        tmpWidthPixelIndex = -1;
        while originBlock ~= tmpBlock
            tmpBlock = originBlock;
            tmpMAE = sum(abs(int32(currentBlock) - int32(tmpBlock)), "all") / numel(currentBlock);
            if checkFrameBoundary(int32(originWidthPixelIndex), int32(originHeightPixelIndex)-blockSize, blockSize, frame) == 1
                refBlock = frame(int32(originHeightPixelIndex)-blockSize:originHeightPixelIndex-1, originWidthPixelIndex:originWidthPixelIndex+blockSize-1);
                mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
                if mae < tmpMAE 
                    tmpMAE = mae;
                    tmpHeightPixelIndex = int32(originHeightPixelIndex)-blockSize;
                    tmpWidthPixelIndex = int32(originWidthPixelIndex);
                end
            end
            if checkFrameBoundary(int32(originWidthPixelIndex)-blockSize, int32(originHeightPixelIndex), blockSize, frame) == 1
                refBlock = frame(int32(originHeightPixelIndex):originHeightPixelIndex+blockSize-1, int32(originWidthPixelIndex)-blockSize:originWidthPixelIndex-1);
                mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
                if mae < tmpMAE 
                    tmpMAE = mae;
                    tmpHeightPixelIndex = int32(originHeightPixelIndex);
                    tmpWidthPixelIndex = int32(originWidthPixelIndex)-blockSize
                end
            end
            if checkFrameBoundary(int32(originWidthPixelIndex), int32(originHeightPixelIndex)+blockSize, blockSize, frame) == 1
                refBlock = frame(int32(originHeightPixelIndex)-blockSize:originHeightPixelIndex-1, originWidthPixelIndex:originWidthPixelIndex+blockSize-1);
                mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
                if mae < tmpMAE 
                    tmpMAE = mae;
                    tmpHeightPixelIndex = int32(originHeightPixelIndex)-blockSize;
                    tmpWidthPixelIndex = int32(originWidthPixelIndex);
                end
            end
            if checkFrameBoundary(int32(originWidthPixelIndex)+blockSize, int32(originHeightPixelIndex), blockSize, frame) == 1
                refBlock = frame(int32(originHeightPixelIndex)-blockSize:originHeightPixelIndex-1, originWidthPixelIndex:originWidthPixelIndex+blockSize-1);
                mae = sum(abs(int32(currentBlock) - int32(refBlock)), "all") / numel(currentBlock);
                if mae < tmpMAE 
                    tmpMAE = mae;
                    tmpHeightPixelIndex = int32(originHeightPixelIndex)-blockSize;
                    tmpWidthPixelIndex = int32(originWidthPixelIndex);
                end
            end
        end
    end
end
