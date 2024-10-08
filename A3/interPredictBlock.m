function [split, bestMV, encodedQuantizedBlock, reconstructedBlock] = interPredictBlock(...
    refFrames, interpolateRefFrames, currentFrame, widthBlockIndex, heightBlockIndex,r,blockSize, QP, VBSEnable, FMEEnable, FastME, MVP, Lambda, RCFlag, previousPassSplitDecision)

% return values:
%     split: boolean indicating whether we split this block
%     bestMV: when split==false, bestMV is of shape 1*3. When split==true,
%         bestMV is of shape 4*3
%     encodedQuantizedBlock: when split==false, encodedQuantizedBlock is a string array. When split==true,
%         encodedQuantizedBlock is matrix of string array of shape 1*4
%     reconstructedBlock: of shape blockSize * blockSize

widthPixelIndex = int32((int32(widthBlockIndex)-1)*blockSize + 1);
heightPixelIndex = int32((int32(heightBlockIndex)-1)*blockSize + 1);
splitSize = blockSize / 2;

bestMAESplit = Inf(1, 4);
bestMVSplit = int32(zeros(4,3));
referenceBlockSplit = zeros(splitSize, splitSize, 4);
residualBlockSplit = zeros(splitSize, splitSize, 4);
reconstructedBlock = int32(zeros(blockSize, blockSize));

if ~(RCFlag == 3 && previousPassSplitDecision == true)
    if FastME == false
        if FMEEnable
            [bestMVNonSplit, bestMAENonSplit, referenceBlockNonSplit, residualBlockNonSplit] = fractionalPixelFullSearch(interpolateRefFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r);
        else
            [bestMVNonSplit, bestMAENonSplit, referenceBlockNonSplit, residualBlockNonSplit] = integerPixelFullSearch(refFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r);
        end
    else
        if FMEEnable
            [bestMVNonSplit, bestMAENonSplit, referenceBlockNonSplit, residualBlockNonSplit] = fractionalFastMotionEstimation(interpolateRefFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, MVP);
        else
            [bestMVNonSplit, bestMAENonSplit, referenceBlockNonSplit, residualBlockNonSplit] = fastMotionEstimation(refFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, MVP);
        end
    end
end

if VBSEnable == false || (RCFlag == 3 && previousPassSplitDecision == false)
    split = false;
    bestMV = int32(bestMVNonSplit);
    [encodedQuantizedBlock, quantizedBlock] = dctQuantizeAndEncode(residualBlockNonSplit, QP, blockSize);
    rescaledBlock = rescaling(quantizedBlock, QP);

    approximatedResidualBlock = idct2(rescaledBlock);
    reconstructedBlock = int32(approximatedResidualBlock) + int32(referenceBlockNonSplit);
else
    topLeftWidthPixelIndex = widthPixelIndex;
    topLeftHeightPixelIndex = heightPixelIndex;

    topRightWidthPixelIndex = widthPixelIndex + splitSize;
    topRightHeightPixelIndex = heightPixelIndex;

    bottomLeftWidthPixelIndex = widthPixelIndex;
    bottomLeftHeightPixelIndex = heightPixelIndex + splitSize;

    bottomRightWidthPixelIndex = widthPixelIndex + splitSize;
    bottomRightHeightPixelIndex = heightPixelIndex + splitSize;

    % top left
    if FastME == false
        if FMEEnable
            [bestMVSplit(1, :), bestMAESplit(1, 1), referenceBlockSplit(:, :, 1), residualBlockSplit(:, :, 1)] = fractionalPixelFullSearch(interpolateRefFrames, currentFrame, topLeftWidthPixelIndex, topLeftHeightPixelIndex, splitSize, r);
        else
            [bestMVSplit(1, :), bestMAESplit(1, 1), referenceBlockSplit(:, :, 1), residualBlockSplit(:, :, 1)] = integerPixelFullSearch(refFrames, currentFrame, topLeftWidthPixelIndex, topLeftHeightPixelIndex, splitSize, r);
        end
    else
        if FMEEnable
            [bestMVSplit(1, :), bestMAESplit(1, 1), referenceBlockSplit(:, :, 1), residualBlockSplit(:, :, 1)] = fractionalFastMotionEstimation(interpolateRefFrames, currentFrame, topLeftWidthPixelIndex, topLeftHeightPixelIndex, splitSize, MVP);
        else
            [bestMVSplit(1, :), bestMAESplit(1, 1), referenceBlockSplit(:, :, 1), residualBlockSplit(:, :, 1)] = fastMotionEstimation(refFrames, currentFrame, topLeftWidthPixelIndex, topLeftHeightPixelIndex, splitSize, MVP);
        end
    end

    % top right
    if FastME == false
        if FMEEnable
            [bestMVSplit(2, :), bestMAESplit(1, 2), referenceBlockSplit(:, :, 2), residualBlockSplit(:, :, 2)] = fractionalPixelFullSearch(interpolateRefFrames, currentFrame, topRightWidthPixelIndex, topLeftHeightPixelIndex, splitSize, r);
        else
            [bestMVSplit(2, :), bestMAESplit(1, 2), referenceBlockSplit(:, :, 2), residualBlockSplit(:, :, 2)] = integerPixelFullSearch(refFrames, currentFrame, topRightWidthPixelIndex, topRightHeightPixelIndex, splitSize, r);
        end
    else
        if FMEEnable
            [bestMVSplit(2, :), bestMAESplit(1, 2), referenceBlockSplit(:, :, 2), residualBlockSplit(:, :, 2)] = fractionalFastMotionEstimation(interpolateRefFrames, currentFrame, topRightWidthPixelIndex, topRightHeightPixelIndex, splitSize, bestMVSplit(1, :));
        else
            [bestMVSplit(2, :), bestMAESplit(1, 2), referenceBlockSplit(:, :, 2), residualBlockSplit(:, :, 2)] = fastMotionEstimation(refFrames, currentFrame, topRightWidthPixelIndex, topRightHeightPixelIndex, splitSize, bestMVSplit(1, :));
        end
    end

    % bottom left
    if FastME == false
        if FMEEnable
            [bestMVSplit(3, :), bestMAESplit(1, 3), referenceBlockSplit(:, :, 3), residualBlockSplit(:, :, 3)] = fractionalPixelFullSearch(interpolateRefFrames, currentFrame, bottomLeftWidthPixelIndex, bottomLeftHeightPixelIndex, splitSize, r);
        else
            [bestMVSplit(3, :), bestMAESplit(1, 3), referenceBlockSplit(:, :, 3), residualBlockSplit(:, :, 3)] = integerPixelFullSearch(refFrames, currentFrame, bottomLeftWidthPixelIndex, bottomLeftHeightPixelIndex, splitSize, r);
        end
    else
        if FMEEnable
            [bestMVSplit(3, :), bestMAESplit(1, 3), referenceBlockSplit(:, :, 3), residualBlockSplit(:, :, 3)] = fractionalFastMotionEstimation(interpolateRefFrames, currentFrame, bottomLeftWidthPixelIndex, bottomLeftHeightPixelIndex, splitSize, bestMVSplit(2, :));
        else
            [bestMVSplit(3, :), bestMAESplit(1, 3), referenceBlockSplit(:, :, 3), residualBlockSplit(:, :, 3)] = fastMotionEstimation(refFrames, currentFrame, bottomLeftWidthPixelIndex, bottomLeftHeightPixelIndex, splitSize, bestMVSplit(2, :));
        end
    end

    % bottom right
    if FastME == false
        if FMEEnable
            [bestMVSplit(4, :), bestMAESplit(1, 4), referenceBlockSplit(:, :, 4), residualBlockSplit(:, :, 4)] = fractionalPixelFullSearch(interpolateRefFrames, currentFrame, bottomRightWidthPixelIndex, bottomRightHeightPixelIndex, splitSize, r);
        else
            [bestMVSplit(4, :), bestMAESplit(1, 4), referenceBlockSplit(:, :, 4), residualBlockSplit(:, :, 4)] = integerPixelFullSearch(refFrames, currentFrame, bottomRightWidthPixelIndex, bottomRightHeightPixelIndex, splitSize, r);
        end
    else
        if FMEEnable
            [bestMVSplit(4, :), bestMAESplit(1, 4), referenceBlockSplit(:, :, 4), residualBlockSplit(:, :, 4)] = fractionalFastMotionEstimation(interpolateRefFrames, currentFrame, bottomRightWidthPixelIndex, bottomRightHeightPixelIndex, splitSize, bestMVSplit(3, :));
        else
            [bestMVSplit(4, :), bestMAESplit(1, 4), referenceBlockSplit(:, :, 4), residualBlockSplit(:, :, 4)] = fastMotionEstimation(refFrames, currentFrame, bottomRightWidthPixelIndex, bottomRightHeightPixelIndex, splitSize, bestMVSplit(3, :));
        end
    end

    if ~(RCFlag == 3 && previousPassSplitDecision == true)
        SADNonSplit = bestMAENonSplit * blockSize * blockSize;
        totalBitsNonSplit = 0;
        [encodedQuantizedBlockNonSplit, quantizedBlockNonSplit] = dctQuantizeAndEncode(residualBlockNonSplit, QP, blockSize);
        totalBitsNonSplit = totalBitsNonSplit + strlength(encodedQuantizedBlockNonSplit);
    
        SADSplit = sum(bestMAESplit, "all") * splitSize * splitSize;
    end
    
    totalBitsSplit = 0;

    smallBlockQP = QP - 1;
    if smallBlockQP < 0
        smallBlockQP = 0;
    end

    encodedQuantizedBlockSplit = strings(1, 4);
    quantizedBlockSplit = zeros(splitSize, splitSize, 4);
    for splitIndex = 1:4
        [encodedQuantizedBlockSplit(1, splitIndex), quantizedBlockSplit(:, :, splitIndex)] = ...
            dctQuantizeAndEncode(residualBlockSplit(:, :, splitIndex), smallBlockQP, splitSize);
        totalBitsSplit = totalBitsSplit + strlength(encodedQuantizedBlockSplit(1, splitIndex));
    end

    if ~(RCFlag == 3 && previousPassSplitDecision == true)
        % for MVs
        totalBitsNonSplit = totalBitsNonSplit + strlength(expGolombEncoding(RLE(int32(bestMVNonSplit) - MVP)));
        % note we need to transpose bestMVSplit first before reshaping to get
        % row-wise reshaping
        % reshape([1,2,3; 4,5,6]', 1, []) = [1 2 3 4 5 6]
        bestMVSplitDifferentialEncoded = int32(bestMVSplit);
        bestMVSplitDifferentialEncoded(1, :) = bestMVSplit(1, :) - MVP;
        bestMVSplitDifferentialEncoded(2, :) = bestMVSplit(2, :) - bestMVSplit(1, :);
        bestMVSplitDifferentialEncoded(3, :) = bestMVSplit(3, :) - bestMVSplit(3, :);
        bestMVSplitDifferentialEncoded(4, :) = bestMVSplit(4, :) - bestMVSplit(4, :);
        totalBitsSplit = totalBitsSplit + strlength(expGolombEncoding(RLE(reshape(bestMVSplitDifferentialEncoded', 1, []))));

        JNonSplit = SADNonSplit + Lambda * totalBitsNonSplit;
        Jsplit = SADSplit + Lambda * totalBitsSplit;
    end

    if (RCFlag == 3 && previousPassSplitDecision == true) || Jsplit < JNonSplit
        split = true;
        bestMV = bestMVSplit;

        encodedQuantizedBlock = encodedQuantizedBlockSplit;

        rescaledBlock = rescaling(quantizedBlockSplit(:, :, 1), smallBlockQP);
        approximatedResidualBlock = idct2(rescaledBlock);
        reconstructedBlock(1:splitSize, 1:splitSize) = int32(approximatedResidualBlock) + int32(referenceBlockSplit(:, : ,1));

        rescaledBlock = rescaling(quantizedBlockSplit(:, :, 2), smallBlockQP);
        approximatedResidualBlock = idct2(rescaledBlock);
        reconstructedBlock(1:splitSize, splitSize+1:2*splitSize) = int32(approximatedResidualBlock) + int32(referenceBlockSplit(:, : ,2));

        rescaledBlock = rescaling(quantizedBlockSplit(:, :, 3), smallBlockQP);
        approximatedResidualBlock = idct2(rescaledBlock);
        reconstructedBlock(splitSize+1:2*splitSize, 1:splitSize) = int32(approximatedResidualBlock) + int32(referenceBlockSplit(:, : ,3));

        rescaledBlock = rescaling(quantizedBlockSplit(:, :, 4), smallBlockQP);
        approximatedResidualBlock = idct2(rescaledBlock);
        reconstructedBlock(splitSize+1:2*splitSize, splitSize+1:2*splitSize) = int32(approximatedResidualBlock) + int32(referenceBlockSplit(:, : ,4));
    else
        split = false;
        bestMV = int32(bestMVNonSplit);
        encodedQuantizedBlock = encodedQuantizedBlockNonSplit;
        rescaledBlock = rescaling(quantizedBlockNonSplit, QP);
        approximatedResidualBlock = idct2(rescaledBlock);
        reconstructedBlock = int32(approximatedResidualBlock) + int32(referenceBlockNonSplit);
    end
end

end