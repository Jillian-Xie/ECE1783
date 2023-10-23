function [modeCell,I_blockCell, reconstructedFrame] = intraPrediction(currentFrame, blockSize)

height = size(currentFrame,1);
width  = size(currentFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

modeCell = cell(heightBlockNum, widthBlockNum);
I_blockCell = cell(heightBlockNum, widthBlockNum);
reconstructedFrame(1:height,1:width) = uint8(128);

for heightBlockIndex = 1:heightBlockNum
    for widthBlockIndex = 1:widthBlockNum
        currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);
        [verticalReffernce, horizontalRefference] = getRefference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize);
        [mode, predictedBlock] = intraPredictBlock(verticalReffernce, horizontalRefference, currentBlock, blockSize);
        modeCell{heightBlockIndex, widthBlockIndex} = mode;
        I_blockCell{heightBlockIndex, widthBlockIndex} = predictedBlock;
        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = predictedBlock;
    end
end

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
