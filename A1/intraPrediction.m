function [modeCell,I_blockCell, reconstructedFrame] = intraPrediction(currentFrame, blockSize)

width  = size(currentFrame,1);
height = size(currentFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

modeCell = cell(widthBlockNum, heightBlockNum);
I_blockCell = cell(widthBlockNum, heightBlockNum);
reconstructedFrame = uint8(zeros(width, height));

for widthBlockIndex = 1:widthBlockNum
    for heightBlockIndex = 1:heightBlockNum
        [mode, predictedBlock] = intraPredictBlock(currentFrame, widthBlockIndex, heightBlockIndex, blockSize);
        modeCell{widthBlockIndex, heightBlockIndex} = mode;
        I_blockCell{widthBlockIndex, heightBlockIndex} = predictedBlock;
        reconstructedFrame((widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize, (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize) = predictedBlock;
    end
end

