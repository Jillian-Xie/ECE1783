function [bestMV, quantizedBlock, reconstructedBlock] = interPredictBlock(refFrame, currentFrame, widthBlockIndex, heightBlockIndex,r,blockSize, QP, VBSEnable, FMEEnable, FastME)

widthPixelIndex = int32((int32(widthBlockIndex)-1)*blockSize + 1);
heightPixelIndex = int32((int32(heightBlockIndex)-1)*blockSize + 1);

if FastME
    [bestMV, referenceBlock, residualBlock] = integerPixelFullSearch(refFrame, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r);
else
    [bestMV, referenceBlock, residualBlock] = fastMotionEstimation(refFrame, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r);
end

bestMV = int32(bestMV);
transformedBlock = dct2(residualBlock);
quantizedBlock = quantize(transformedBlock, QP);
rescaledBlock = rescaling(quantizedBlock, QP);

approximatedResidualBlock = idct2(rescaledBlock);
reconstructedBlock = int32(approximatedResidualBlock) + int32(referenceBlock);