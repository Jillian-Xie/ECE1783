function [MVCell, QTCCoeffsFrame, MDiffsFrame, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = ex4_motionEstimate(referenceFrame,currentFrame,blockSize,r, QP)

height = size(referenceFrame,1);
width  = size(referenceFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

MVCell = cell(heightBlockNum, widthBlockNum);
approximatedResidualCell = cell(heightBlockNum, widthBlockNum);
approximatedResidualFrame = uint8(zeros(height, width));
reconstructedFrame = uint8(zeros(height, width));

QTCCoeffsFrame = strings([1, widthBlockNum * heightBlockNum]);
MDiffsInt = [];

for heightBlockIndex = 1:heightBlockNum
    for widthBlockIndex = 1:widthBlockNum
        previousMV = int32([0, 0]);
        [bestMAE, bestMV, quantizedBlock, approximatedResidualBlock, reconstructedBlock] = ex4_encodeBlock(referenceFrame, currentFrame, widthBlockIndex, heightBlockIndex, r,blockSize, QP);
        
        encodedQuantizedBlock = encodeQuantizedBlock(quantizedBlock, blockSize);
        QTCCoeffsFrame(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex) = encodedQuantizedBlock;
        
        % differential encoding
        MDiffsInt = [MDiffsInt, bestMV - previousMV];
        previousMV = bestMV;
        
        MVCell{heightBlockIndex, widthBlockIndex} = bestMV;
        approximatedResidualCell{heightBlockIndex, widthBlockIndex} = approximatedResidualBlock;
        approximatedResidualFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = approximatedResidualBlock;
        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = reconstructedBlock;
    end
end

MDiffRLE = RLE(MDiffsInt);
MDiffsFrame = expGolombEncoding(MDiffRLE);