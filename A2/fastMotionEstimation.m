function [bestMV, referenceBlock, residualBlock] = fastMotionEstimation(refFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, MVP)
% TODO
bestMAE = Inf;
bestMV = int32([0, 0, 0]);

currentBlock = currentFrame(heightPixelIndex:heightPixelIndex+blockSize-1,widthPixelIndex:widthPixelIndex+blockSize-1);

referenceBlock = 0;
residualBlock = 0;

numRefFrames = size(refFrames,3);
for indexRefFrame = 1:numRefFrames
    refFrame = refFrames(:,:,indexRefFrame);
    
end
