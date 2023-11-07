function [bestMV, referenceBlock, residualBlock] = fastMotionEstimation(refFrame, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, MVP)
% TODO
bestMAE = Inf;
bestMV = int32([0, 0, 0]);

currentBlock = currentFrame(heightPixelIndex:heightPixelIndex+blockSize-1,widthPixelIndex:widthPixelIndex+blockSize-1);

referenceBlock = 0;
residualBlock = 0;

numRefFrames = size(refFrame,3);
for indexRefFrame = 1:numRefFrames
    frame = refFrame(:,:,indexRefFrame);
    
end
