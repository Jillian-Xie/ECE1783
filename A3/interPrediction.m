function [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent, perRowBitCount, avgQP, splitInt] = interPrediction( ...
            referenceFrames, interpolateRefFrames, currentFrame, blockSize, r, QP, ...
            VBSEnable, FMEEnable, FastME, RCFlag, frameTotalBits, QPs, statistics, perRowBitCountStatistics, previousPassSplitDecision)

% return values:
%     splitFrame is to be ignored if VBSEnable == false

height = size(referenceFrames,1);
width  = size(referenceFrames,2);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

reconstructedFrame = int32(zeros(height, width));

QTCCoeffsFrame = strings(0);
MDiffsInt = [];
splitInt = [];
QPInt = [1]; % encode the first bit as 0 to signify this is an P-frame
perRowBitCount = [];

actualBitSpent = int32(0);
previousQP = 6; % assume QP=6 in the beginning
avgQP = 0;

for heightBlockIndex = 1:heightBlockNum
    % MV by default is [0,0,0] => [x, y, refFrame]
    previousMV = int32([0, 0, 0]);
    if RCFlag == 1
        budget = double(frameTotalBits-actualBitSpent)/double(heightBlockNum-heightBlockIndex+1);
        [currentQP, ~] = getCurrentQP(QPs, statistics{2}, int32(budget));
    elseif RCFlag == 2 || RCFlag == 3
        budget = frameTotalBits * (double(perRowBitCountStatistics(1, heightBlockIndex)) / double(sum(perRowBitCountStatistics, 'all')));
        [currentQP, ~] = getCurrentQP(QPs, statistics{2}, int32(budget));
    else
        currentQP = QP;
    end
    Lambda = getLambda(currentQP);

    for widthBlockIndex = 1:widthBlockNum
        
        [split, bestMV, encodedQuantizedBlock, reconstructedBlock] = interPredictBlock( ...
            referenceFrames, interpolateRefFrames, currentFrame, widthBlockIndex, heightBlockIndex, ...
            r,blockSize, currentQP, VBSEnable, FMEEnable, FastME, previousMV, Lambda, RCFlag, previousPassSplitDecision(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex));

        splitInt = [splitInt, split];
        QTCCoeffsFrame = [QTCCoeffsFrame, encodedQuantizedBlock];
        
        if VBSEnable && split
            for i = 1:4
                MDiffsInt = [MDiffsInt, bestMV(i, :) - previousMV];
                previousMV = bestMV(i, :);
            end
        else
            % Differential encoding
            MDiffsInt = [MDiffsInt, bestMV - previousMV];
            previousMV = bestMV;
        end
        
        reconstructedFrame( ...
            (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, ...
            (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize ...
            ) = reconstructedBlock;
    end

    QPInt = [QPInt, currentQP - previousQP];
    avgQP = avgQP + currentQP;
    previousQP = currentQP;
    
    currentBitSpent = getActualBitSpent(QTCCoeffsFrame, MDiffsInt, splitInt, QPInt);
    actualBitSpentRow = currentBitSpent - actualBitSpent;
    actualBitSpent = currentBitSpent;
    perRowBitCount = [perRowBitCount, actualBitSpentRow];
end

MDiffRLE = RLE(MDiffsInt);
MDiffsFrame = expGolombEncoding(MDiffRLE);

splitRLE = RLE(splitInt);
splitFrame = expGolombEncoding(splitRLE);

QPRLE = RLE(QPInt);
QPFrame = expGolombEncoding(QPRLE);

avgQP = avgQP / double(heightBlockNum);

end