function MVCell = motionEstimate(referenceFrame,currentFrame,blockSize,r)

width  = size(referenceFrame,1);
height = size(referenceFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

MVCell = cell(widthBlockNum, heightBlockNum);

for widthBlockIndex = 1:widthBlockNum
    for heightBlockIndex = 1:heightBlockNum
        [bestMAE, bestMV, residualBlock] = getBestMV(referenceFrame, currentFrame, widthBlockIndex, heightBlockIndex, r,blockSize);
        MVCell{widthBlockIndex, heightBlockIndex} = bestMV;
    end
end


