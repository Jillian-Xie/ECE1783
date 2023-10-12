function [MVCell, approximatedResidualCell] = motionEstimate(referenceFrame,currentFrame,blockSize,r,n)

width  = size(referenceFrame,1);
height = size(referenceFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

MVCell = cell(widthBlockNum, heightBlockNum);
approximatedResidualCell = cell(widthBlockNum, heightBlockNum);

for widthBlockIndex = 1:widthBlockNum
    for heightBlockIndex = 1:heightBlockNum
        [bestMAE, bestMV, approximatedResidualBlock, reconstructedBlock] = encodeBlock(referenceFrame, currentFrame, widthBlockIndex, heightBlockIndex, r,blockSize,n);
        MVCell{widthBlockIndex, heightBlockIndex} = bestMV;
        approximatedResidualCell{widthBlockIndex, heightBlockIndex} = approximatedResidualBlock;
    end
end


