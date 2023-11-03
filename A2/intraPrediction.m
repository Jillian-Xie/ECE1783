function [QTCCoeffsFrame, MDiffsFrame, reconstructedFrame] = intraPrediction(currentFrame, blockSize,QP)

height = size(currentFrame,1);
width  = size(currentFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

modes = zeros(heightBlockNum, widthBlockNum);
reconstructedFrame(1:height,1:width) = uint8(128);
approximatedResidualFrame = uint8(zeros(height, width));

QTCCoeffsFrame = strings([1, widthBlockNum * heightBlockNum]);
MDiffsInt = [];

for heightBlockIndex = 1:heightBlockNum
    previousMode = int32(0); % assume horizontal in the beginning
    for widthBlockIndex = 1:widthBlockNum
      
        currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);
        
        % the left-𝑖 (or top-𝑖) border reconstructed samples
        [verticalRefernce, horizontalReference] = getIntraPredictionReference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize);
        [mode, quantizedBlock, approximatedResidualBlock, reconstructedBlock] = intraPredictBlock(verticalRefernce, horizontalReference, currentBlock, blockSize,QP);
        
        encodedQuantizedBlock = encodeQuantizedBlock(quantizedBlock, blockSize);
        QTCCoeffsFrame(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex) = encodedQuantizedBlock;
        
        % differential encoding
        MDiffsInt = [MDiffsInt, xor(mode, previousMode)]; % 0 = no change, 1 = changed
        previousMode = mode;
        
        modes(heightBlockIndex, widthBlockIndex) = mode;
        approximatedResidualFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = approximatedResidualBlock;
        
        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = reconstructedBlock;
    end
end

MDiffRLE = RLE(MDiffsInt);
MDiffsFrame = expGolombEncoding(MDiffRLE);

end