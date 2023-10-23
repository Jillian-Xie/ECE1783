function [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = ex4_motionEstimate(referenceFrame,currentFrame,blockSize,r,n,QP)

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
        [bestMAE, bestMV, quantizedBlock, approximatedResidualBlock, reconstructedBlock] = ex4_encodeBlock(referenceFrame, currentFrame, widthBlockIndex, heightBlockIndex, r,blockSize,n,QP);
        
%         encodedQuantizedBlock = encodeQuantizedBlock(quantizedBlock, blockSize);
        MVCell{widthBlockIndex, heightBlockIndex} = bestMV;
        approximatedResidualCell{widthBlockIndex, heightBlockIndex} = approximatedResidualBlock;
        approximatedResidualFrame((widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize, (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize) = approximatedResidualBlock;
        reconstructedFrame((widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize, (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize) = reconstructedBlock;
    end
end


