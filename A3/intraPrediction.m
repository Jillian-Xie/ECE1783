function [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent] = intraPrediction( ...
    currentFrame, blockSize,QP, VBSEnable, FMEEnable, FastME, RCFlag, ...
    frameTotalBits, QPs, statistics)

% return values:
%     splitFrame is to be ignored if VBSEnable == false

height = size(currentFrame,1);
width  = size(currentFrame,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

reconstructedFrame(1:height,1:width) = int32(128);

QTCCoeffsFrame = strings(0);
MDiffsInt = [];
splitInt = [];
QPInt = [0]; % encode the first bit as 0 to signify this is an I-frame

actualBitSpent = int32(0);
previousQP = 6; % assume QP=6 in the beginning

for heightBlockIndex = 1:heightBlockNum
    previousMode = int32(0); % assume horizontal in the beginning
    if RCFlag == 1
        budget = double(frameTotalBits-actualBitSpent)/double(heightBlockNum-heightBlockIndex+1);
        currentQP = getCurrentQP(QPs, statistics{1}, int32(budget));
    else
        currentQP = QP;
    end
    Lambda = getLambda(currentQP);
    for widthBlockIndex = 1:widthBlockNum

        currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);

        % the left-𝑖 (or top-𝑖) border reconstructed samples
        [verticalRefernce, horizontalReference] = getIntraPredictionReference( ...
            heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize ...
            );
        [split, mode, encodedQuantizedBlock, reconstructedBlock] = intraPredictBlock( ...
            verticalRefernce, horizontalReference, currentBlock, blockSize, ...
            currentQP, previousMode, VBSEnable, FMEEnable, FastME, Lambda);

        splitInt = [splitInt, split];
        QTCCoeffsFrame = [QTCCoeffsFrame, encodedQuantizedBlock];

        if VBSEnable && split
            for i = 1:4
                MDiffsInt = [MDiffsInt, xor(mode(1, i), previousMode)]; % 0 = no change, 1 = changed
                previousMode = mode(1, i);
            end
        else
            % differential encoding
            MDiffsInt = [MDiffsInt, xor(mode, previousMode)]; % 0 = no change, 1 = changed
            previousMode = mode;
        end

        reconstructedFrame( ...
            (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, ...
            (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize ...
            ) = reconstructedBlock;
    end
    
    % Differential encoding
    QPInt = [QPInt, currentQP - previousQP];
    previousQP = currentQP;
    actualBitSpent = getActualBitSpent(QTCCoeffsFrame, MDiffsInt, splitInt, QPInt);
end

MDiffRLE = RLE(MDiffsInt);
MDiffsFrame = expGolombEncoding(MDiffRLE);

splitRLE = RLE(splitInt);
splitFrame = expGolombEncoding(splitRLE);

QPRLE = RLE(QPInt);
QPFrame = expGolombEncoding(QPRLE);

end