function [modeCell,I_blockCell, reconstructedFrame] = intraPrediction(currentFrame, blockSize)

height = size(currentFrame,1);
width  = size(currentFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

modeCell = cell(heightBlockNum, widthBlockNum);
I_blockCell = cell(heightBlockNum, widthBlockNum);
reconstructedFrame = uint8(zeros(height, width));

for heightBlockIndex = 1:heightBlockNum
    for widthBlockIndex = 1:widthBlockNum
        [mode, predictedBlock] = intraPredictBlock(currentFrame, widthBlockIndex, heightBlockIndex, blockSize);
        modeCell{heightBlockIndex, widthBlockIndex} = mode;
        I_blockCell{heightBlockIndex, widthBlockIndex} = predictedBlock;
        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = predictedBlock;
    end
end

