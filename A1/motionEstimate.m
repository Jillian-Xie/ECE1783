function MVCell = motionEstimate(referenceFrame,currentFrame,blockSize, r, n)

width  = size(referenceFrame,1);
height = size(referenceFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

reconstructedFrame = int32(zeros(width, height));
approximatedResidualFrame = int32(zeros(width, height));

MVCell = cell(widthBlockNum, heightBlockNum);

for widthBlockIndex = 1:widthBlockNum
    for heightBlockIndex = 1:heightBlockNum
        [bestMAE, bestMV, residualBlock, approximatedResidualBlock] = getBestMV(referenceFrame, currentFrame, widthBlockIndex, heightBlockIndex, r, blockSize, n);
        MVCell{widthBlockIndex, heightBlockIndex} = bestMV;
        reconstructedBlock = referenceFrame + approximatedResidualBlock;
    end
end


