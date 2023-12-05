function [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame, actualBitSpent, perRowBitCount, avgQP, splitInt] = intraPrediction( ...
    currentFrame, blockSize,QP, VBSEnable, FMEEnable, FastME, RCFlag, ...
    frameTotalBits, QPs, statistics, perRowBitCountStatistics, previousPassSplitDecision)

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
perRowBitCount = [];

actualBitSpent = int32(0);
previousQP = 6; % assume QP=6 in the beginning
avgQP = 0;

for heightBlockIndex = 1:heightBlockNum
    previousMode = int32(0); % assume horizontal in the beginning
    if RCFlag == 1
        budget = double(frameTotalBits-actualBitSpent)/double(heightBlockNum-heightBlockIndex+1);
        [currentQP, ~] = getCurrentQP(QPs, statistics{1}, int32(budget));
    elseif RCFlag == 2 || RCFlag == 3
        budget = frameTotalBits * (double(perRowBitCountStatistics(1, heightBlockIndex)) / double(sum(perRowBitCountStatistics, 'all')));
        [currentQP, ~] = getCurrentQP(QPs, statistics{1}, int32(budget));
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
            currentQP, previousMode, VBSEnable, FMEEnable, FastME, Lambda, RCFlag, previousPassSplitDecision(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex));

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