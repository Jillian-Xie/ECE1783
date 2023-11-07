function [bestMV, quantizedBlock, reconstructedBlock] = interPredictBlock(refFrames, currentFrame, widthBlockIndex, heightBlockIndex,r,blockSize, QP, VBSEnable, FMEEnable, FastME, MVP)

widthPixelIndex = int32((int32(widthBlockIndex)-1)*blockSize + 1);
heightPixelIndex = int32((int32(heightBlockIndex)-1)*blockSize + 1);

if FastME == false
    [bestMV, referenceBlock, residualBlock] = integerPixelFullSearch(refFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r, VBSEnable);
else
    [bestMV, referenceBlock, residualBlock] = fastMotionEstimation(refFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, MVP);
end

bestMV = int32(bestMV);
transformedBlock = dct2(residualBlock);
quantizedBlock = quantize(transformedBlock, QP);
rescaledBlock = rescaling(quantizedBlock, QP);

approximatedResidualBlock = idct2(rescaledBlock);
reconstructedBlock = int32(approximatedResidualBlock) + int32(referenceBlock);