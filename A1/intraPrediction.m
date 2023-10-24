function [modes, QTCCoeffsFrame, MDiffsFrame, approximatedResidualCell, approximatedResidualFrame, reconstructedFrame] = intraPrediction(currentFrame, blockSize,QP)

height = size(currentFrame,1);
width  = size(currentFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

modes = zeros(heightBlockNum, widthBlockNum);
reconstructedFrame(1:height,1:width) = uint8(128);
approximatedResidualCell = cell(heightBlockNum, widthBlockNum);
approximatedResidualFrame = uint8(zeros(height, width));

QTCCoeffsFrame = strings([1, widthBlockNum * heightBlockNum]);
MDiffsInt = [];

for heightBlockIndex = 1:heightBlockNum
    for widthBlockIndex = 1:widthBlockNum
        previousMode = int32(0); % assume horizontal in the beginning
        currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);
        
        [verticalReffernce, horizontalRefference] = getRefference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize);
        [mode, quantizedBlock, approximatedResidualBlock, reconstructedBlock] = intraPredictBlock(verticalReffernce, horizontalRefference, currentBlock, blockSize,QP);
        
        encodedQuantizedBlock = encodeQuantizedBlock(quantizedBlock, blockSize);
        QTCCoeffsFrame(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex) = encodedQuantizedBlock;
        
        % differential encoding
        MDiffsInt = [MDiffsInt, xor(mode, previousMode)]; % 0 = no change, 1 = changed
        previousMode = mode;
        
        modes(heightBlockIndex, widthBlockIndex) = mode;
        
        approximatedResidualCell{heightBlockIndex, widthBlockIndex} = approximatedResidualBlock;
        approximatedResidualFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = approximatedResidualBlock;
        
        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = reconstructedBlock;
    end
end

MDiffRLE = RLE(MDiffsInt);
MDiffsFrame = expGolombEncoding(MDiffRLE);

end

function [verticalReffernce, horizontalRefference] = getRefference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize)
verticalReffernce(1:1,1:blockSize) = uint8(128);
horizontalRefference(1:blockSize,1:1) = uint8(128);

widthStart = int32((widthBlockIndex-1)*blockSize + 1);
widthEnd = int32(widthStart + blockSize - 1);
heightStart = int32((heightBlockIndex-1)*blockSize + 1);
heightEnd = int32(heightStart + blockSize - 1);

if (heightBlockIndex > 1)
    verticalReffernce = reconstructedFrame(heightStart-1, widthStart:widthEnd);
end
if (widthBlockIndex > 1)
    horizontalRefference = reconstructedFrame(heightStart:heightEnd, widthStart-1);
end
end
