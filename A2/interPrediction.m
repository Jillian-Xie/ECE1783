function [QTCCoeffsFrame, MDiffsFrame, reconstructedFrame] = interPrediction(referenceFrames, currentFrame, blockSize, r, QP, VBSEnable, FMEEnable, FastME)

height = size(referenceFrames,1);
width  = size(referenceFrames,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

reconstructedFrame = uint8(zeros(height, width));

QTCCoeffsFrame = strings([1, widthBlockNum * heightBlockNum]);
MDiffsInt = [];

for heightBlockIndex = 1:heightBlockNum
    % MV by default is [0,0,0] => [x, y, refFrame]
    previousMV = int32([0, 0, 0]);
    for widthBlockIndex = 1:widthBlockNum
        
        [split, bestMV, encodedQuantizedBlock, reconstructedBlock] = interPredictBlock(referenceFrames, currentFrame, widthBlockIndex, heightBlockIndex, r,blockSize, QP, VBSEnable, FMEEnable, FastME, previousMV);

        QTCCoeffsFrame(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex) = encodedQuantizedBlock;
        
        % Differential encoding
        MDiffsInt = [MDiffsInt, bestMV - previousMV];
        previousMV = bestMV;
        
        reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize) = reconstructedBlock;
    end
end

MDiffRLE = RLE(MDiffsInt);
MDiffsFrame = expGolombEncoding(MDiffRLE);