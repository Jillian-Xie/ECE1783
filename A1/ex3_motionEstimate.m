function [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = motionEstimate(referenceFrame,currentFrame,blockSize,r,n)

width  = size(referenceFrame,1);
height = size(referenceFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

MVCell = cell(widthBlockNum, heightBlockNum);
approximatedResidualCell = cell(widthBlockNum, heightBlockNum);
approximatedResidualFrame = uint8(zeros(width, height));
reconstructedFrame = uint8(zeros(width, height));

for widthBlockIndex = 1:widthBlockNum
    for heightBlockIndex = 1:heightBlockNum
        [bestMAE, bestMV, approximatedResidualBlock, reconstructedBlock] = ex3_encodeBlock(referenceFrame, currentFrame, widthBlockIndex, heightBlockIndex, r,blockSize,n);
        MVCell{widthBlockIndex, heightBlockIndex} = bestMV;
        approximatedResidualCell{widthBlockIndex, heightBlockIndex} = approximatedResidualBlock;
        approximatedResidualFrame((widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize, (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize) = approximatedResidualBlock;
        reconstructedFrame((widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize, (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize) = reconstructedBlock;
    end
end


