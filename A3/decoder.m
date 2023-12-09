function splitPercentage = decoder(nFrame, width, height, blockSize, ...
    VBSEnable, FMEEnable, QTCCoeffs, MDiffs, splits, QPFrames, ...
    visualizeVBS, visualizeRGB, visualizeMM, visualizeNRF, encoderReconstructedY, parallelMode)

DecoderOutputPath = 'DecoderOutput\';
reconstructedY = zeros(height, width, nFrame);

if ~exist(DecoderOutputPath,'dir')
    mkdir(DecoderOutputPath)
end

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

refFrameMatrix = ones(heightBlockNum, widthBlockNum, nFrame)*128;

xCell = cell(nFrame);
yCell = cell(nFrame);
uCell = cell(nFrame);
vCell = cell(nFrame);

interpolateRefFrames(1:2*height-1, 1:2*width-1, nFrame) = int32(128);

splitSize = blockSize / 2;

totalSplit = 0;

if parallelMode == 3
    % Parallel processing
    spmd(2)
        framesToDecode = labindex:2:nFrame;
        for currentFrameNum = framesToDecode
            % Insert the frame decoding logic here
            % Decoding of QTCCoeffs, MDiffs, splits, QPFrames, etc.
            QTCCoeff = QTCCoeffs(currentFrameNum, :);
            MDiff = MDiffs(currentFrameNum, 1);
            QPDiffFrame = decodeQPFrame(QPFrames(currentFrameNum, :), heightBlockNum);
            MDiffFrame = expGolombDecoding(convertStringsToChars(MDiff));
            splitFrame = decodeSplitFrame(splits(currentFrameNum, 1), widthBlockNum, heightBlockNum, VBSEnable);

            % Additional decoding steps for each frame
            % E.g., reconstructing the frame based on the decoded data
            reconstructedY(:, :, currentFrameNum) = reconstructFrame(QTCCoeff, MDiffFrame, splitFrame, QPDiffFrame, widthBlockNum, heightBlockNum, blockSize, VBSEnable, FMEEnable);
        end
    end
    % Combine results from parallel workers
    reconstructedY = combineParallelResults(codistributed(reconstructedY));
end

for currentFrameNum = 1:nFrame
    QTCCoeff = QTCCoeffs(currentFrameNum, :);
    MDiff = MDiffs(currentFrameNum, 1);

    % Conditional handling based on parallelMode
    if parallelMode == 1
        % Handle data types appropriately for parallel mode
        QPFramesStr = QPFrames(currentFrameNum, :);
        
        % Convert to string array if it's a cell array
        if iscell(QPFramesStr)
            QPFramesStr = string(QPFramesStr{1}); 
        end

        % Convert to char array
        QPFramesStr = char(QPFramesStr);
        QPFramesStr = QPFramesStr(:)'; % Ensure it's a row vector
        QPFramesStr = regexprep(QPFramesStr, '[^01]', ''); % Remove any character that is not 0 or 1

        QPDiffFrame = reverseRLE(expGolombDecoding(QPFramesStr), heightBlockNum + 1);
        QPDiffFrame = reverseRLE(expGolombDecoding(convertStringsToChars(QPFrames(currentFrameNum, :))), heightBlockNum + 1);
    else
        % Original processing for non-parallel mode
        QPDiffFrame = reverseRLE(expGolombDecoding(convertStringsToChars(QPFrames(currentFrameNum, :))), heightBlockNum + 1);
    end
    
    notIFrame = QPDiffFrame(1, 1);
    QPDiffFrame = QPDiffFrame(1, 2:end);
    MDiffFrame = expGolombDecoding(convertStringsToChars(MDiff));

    xMVMatrix = [];
    yMVMatrix = [];
    uMVMatrix = [];
    vMVMatrix = [];

    if VBSEnable
        if parallelMode == 1
            numSplitted = 0;
            numNonSplitted = widthBlockNum * heightBlockNum;
        else
            splitSequence = splits(currentFrameNum, 1);
            splitFrame = expGolombDecoding(convertStringsToChars(splitSequence));
            splitRLEDecoded = reverseRLE(splitFrame, widthBlockNum * heightBlockNum);
            [numSplitted, numNonSplitted] = countSplitted(splitRLEDecoded, widthBlockNum, heightBlockNum);
            totalSplit = totalSplit + numSplitted;
        end
    else
        numSplitted = 0;
        numNonSplitted = widthBlockNum * heightBlockNum;
    end

    reconstructedFrame(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = int32(128);

    encoderReferenceFrame = encoderReconstructedY(:, :, currentFrameNum);

    if notIFrame == 0
        % I frame
        MDiffRLEDecoded = reverseRLE(MDiffFrame, numNonSplitted + numSplitted * 4);
        previousQP = 6;

        subBlockIndex = 1;
        for heightBlockIndex = 1:heightBlockNum
            previousMode = int32(0); % assume horizontal in the beginning
            currentQP = int32(QPDiffFrame(heightBlockIndex)) + int32(previousQP);
            previousQP = currentQP;
            smallBlockQP = currentQP - 1;
            if smallBlockQP < 0
                smallBlockQP = 0;
            end
            for widthBlockIndex = 1:widthBlockNum
                [verticalReference, horizontalReference] = getIntraPredictionReference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize);
                top = int32((heightBlockIndex-1)*blockSize + 1);
                bottom = int32(heightBlockIndex * blockSize);
                left = int32((widthBlockIndex-1) * blockSize + 1);
                right = int32(widthBlockIndex * blockSize);

                if VBSEnable == false || splitRLEDecoded(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex) == false
                    % do not split this block
                    approximatedResidualBlock = decodeQTCCoeff(QTCCoeff, subBlockIndex, blockSize, currentQP);

                    notSameMode = MDiffRLEDecoded(1, subBlockIndex); % 0 = no change, 1 = changed
                    mode = xor(previousMode, notSameMode);
                    previousMode = mode;

                    if mode == 0
                        % vertical
                        thisBlock = int32(approximatedResidualBlock) + int32(verticalReference);
                        xMVMatrix = [xMVMatrix, left];
                        yMVMatrix = [yMVMatrix, top];
                        uMVMatrix = [uMVMatrix, 0];
                        vMVMatrix = [vMVMatrix, blockSize];
                    else
                        % horizontal
                        thisBlock = int32(approximatedResidualBlock) + int32(horizontalReference);
                        xMVMatrix = [xMVMatrix, left];
                        yMVMatrix = [yMVMatrix, top];
                        uMVMatrix = [uMVMatrix, blockSize];
                        vMVMatrix = [vMVMatrix, 0];
                    end
                    reconstructedFrame(top : bottom, left : right) = thisBlock;

                    encoderReference = encoderReferenceFrame(top : bottom, left : right);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    subBlockIndex = subBlockIndex + 1;
                else
                    % this block is splitted
                    approximatedResidualBlockTopLeft = decodeQTCCoeff(QTCCoeff, subBlockIndex, splitSize, smallBlockQP);
                    approximatedResidualBlockTopRight = decodeQTCCoeff(QTCCoeff, subBlockIndex + 1, splitSize, smallBlockQP);
                    approximatedResidualBlockBottomLeft = decodeQTCCoeff(QTCCoeff, subBlockIndex + 2, splitSize, smallBlockQP);
                    approximatedResidualBlockBottomRight = decodeQTCCoeff(QTCCoeff, subBlockIndex + 3, splitSize, smallBlockQP);

                    notSameModeTopLeft = MDiffRLEDecoded(1, subBlockIndex); % 0 = no change, 1 = changed
                    notSameModeTopRight = MDiffRLEDecoded(1, subBlockIndex + 1); % 0 = no change, 1 = changed
                    notSameModeBottomLeft = MDiffRLEDecoded(1, subBlockIndex + 2); % 0 = no change, 1 = changed
                    notSameModeBottomRight = MDiffRLEDecoded(1, subBlockIndex + 3); % 0 = no change, 1 = changed

                    modeTopLeft = xor(previousMode, notSameModeTopLeft);
                    modeTopRight = xor(modeTopLeft, notSameModeTopRight);
                    modeBottomLeft = xor(modeTopRight, notSameModeBottomLeft);
                    modeBottomRight = xor(modeBottomLeft, notSameModeBottomRight);
                    previousMode = modeBottomRight;

                    % top left
                    if modeTopLeft == 0
                        % vertical
                        thisBlock = int32(approximatedResidualBlockTopLeft) + int32(verticalReference(1, 1:splitSize));
                        xMVMatrix = [xMVMatrix, left];
                        yMVMatrix = [yMVMatrix, top];
                        uMVMatrix = [uMVMatrix, 0];
                        vMVMatrix = [vMVMatrix, splitSize];
                    else
                        % horizontal
                        thisBlock = int32(approximatedResidualBlockTopLeft) + int32(horizontalReference(1:splitSize, 1));
                        xMVMatrix = [xMVMatrix, left];
                        yMVMatrix = [yMVMatrix, top];
                        uMVMatrix = [uMVMatrix, splitSize];
                        vMVMatrix = [vMVMatrix, 0];
                    end
                    reconstructedFrame(top : top + splitSize - 1, left : left + splitSize - 1) = thisBlock;

                    encoderReference = encoderReferenceFrame(top : top + splitSize - 1, left : left + splitSize - 1);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    % top right
                    if modeTopRight == 0
                        % vertical
                        thisBlock = int32(approximatedResidualBlockTopRight) + int32(verticalReference(1, splitSize+1:2*splitSize));
                        xMVMatrix = [xMVMatrix, left+splitSize];
                        yMVMatrix = [yMVMatrix, top];
                        uMVMatrix = [uMVMatrix, 0];
                        vMVMatrix = [vMVMatrix, splitSize];
                    else
                        % horizontal
                        thisBlock = int32(approximatedResidualBlockTopRight) + int32(reconstructedFrame(top : top + splitSize - 1, left + splitSize - 1));
                        xMVMatrix = [xMVMatrix, left+splitSize];
                        yMVMatrix = [yMVMatrix, top];
                        uMVMatrix = [uMVMatrix, splitSize];
                        vMVMatrix = [vMVMatrix, 0];
                    end
                    reconstructedFrame(top : top + splitSize - 1, left + splitSize : right) = thisBlock;

                    encoderReference = encoderReferenceFrame(top : top + splitSize - 1, left + splitSize : right);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    % bottom left
                    if modeBottomLeft == 0
                        % vertical
                        thisBlock = int32(approximatedResidualBlockBottomLeft) + int32(reconstructedFrame(top + splitSize - 1, left : left + splitSize - 1));
                        xMVMatrix = [xMVMatrix, left];
                        yMVMatrix = [yMVMatrix, top+splitSize];
                        uMVMatrix = [uMVMatrix, 0];
                        vMVMatrix = [vMVMatrix, splitSize];
                    else
                        % horizontal
                        thisBlock = int32(approximatedResidualBlockBottomLeft) + int32(horizontalReference(splitSize+1:2*splitSize, 1));
                        xMVMatrix = [xMVMatrix, left];
                        yMVMatrix = [yMVMatrix, top+splitSize];
                        uMVMatrix = [uMVMatrix, splitSize];
                        vMVMatrix = [vMVMatrix, 0];
                    end
                    reconstructedFrame(top + splitSize : bottom, left : left + splitSize - 1) = thisBlock;

                    encoderReference = encoderReferenceFrame(top + splitSize : bottom, left : left + splitSize - 1);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    % bottom right
                    if modeBottomRight == 0
                        % vertical
                        thisBlock = int32(approximatedResidualBlockBottomRight) + int32(reconstructedFrame(top + splitSize - 1, left + splitSize : right));
                        xMVMatrix = [xMVMatrix, left+splitSize];
                        yMVMatrix = [yMVMatrix, top+splitSize];
                        uMVMatrix = [uMVMatrix, 0];
                        vMVMatrix = [vMVMatrix, splitSize];
                    else
                        % horizontal
                        thisBlock = int32(approximatedResidualBlockBottomRight) + int32(reconstructedFrame(top + splitSize : bottom, left + splitSize - 1));
                        xMVMatrix = [xMVMatrix, left+splitSize];
                        yMVMatrix = [yMVMatrix, top+splitSize];
                        uMVMatrix = [uMVMatrix, splitSize];
                        vMVMatrix = [vMVMatrix, 0];
                    end
                    reconstructedFrame(top + splitSize : bottom, left + splitSize : right) = thisBlock;

                    encoderReference = encoderReferenceFrame(top + splitSize : bottom, left + splitSize : right);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    subBlockIndex = subBlockIndex + 4;
                end
            end
        end
    else
        % P frame
        MDiffRLEDecoded = reverseRLE(MDiffFrame, numNonSplitted * 3 + numSplitted * 3 * 4);

        subBlockIndex = 1;
        previousQP = 6;

        for heightBlockIndex = 1:heightBlockNum
            if parallelMode == 1
                currentQP = int32(QPDiffFrame(heightBlockIndex));
            else
                currentQP = int32(QPDiffFrame(heightBlockIndex)) + int32(previousQP);
            end
            previousQP = currentQP;
            smallBlockQP = currentQP - 1;
            if smallBlockQP < 0
                smallBlockQP = 0;
            end
            previousMV = int32([0, 0, 0]);
            for widthBlockIndex = 1:widthBlockNum
                top = int32((heightBlockIndex-1)*blockSize + 1);
                bottom = int32(heightBlockIndex * blockSize);
                left = int32((widthBlockIndex-1) * blockSize + 1);
                right = int32(widthBlockIndex * blockSize);

                if parallelMode == 1 || VBSEnable == false || splitRLEDecoded(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex) == false
                    % do not split this block
                    approximatedResidualBlock = decodeQTCCoeff(QTCCoeff, subBlockIndex, blockSize, currentQP);

                    MVDiff = MDiffRLEDecoded(1, subBlockIndex * 3 - 2 : subBlockIndex * 3);
                    MV = int32(previousMV) + int32(MVDiff);

                    refFrameMatrix(heightBlockIndex, widthBlockIndex, currentFrameNum) = MV(3);

                    previousMV = MV;

                    if FMEEnable
                        if parallelMode ==1
                            refFrame(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = int32(128);
                            thisBlock = int32(approximatedResidualBlock) + int32(refFrame(top + MV(1,1) : bottom + MV(1,1), left + MV(1,2) : right + MV(1,2)));
                        else
                            refFrame = interpolateRefFrames(:,:,currentFrameNum-1-MV(1,3));
                            thisBlock = int32(approximatedResidualBlock) + int32(refFrame(2*top-1 + MV(1,1) :2: 2*top-1 + MV(1,1)+2*(blockSize-1), 2*left-1 + MV(1,2) :2: 2*left-1 + MV(1,2)+2*(blockSize-1)));
                        end
                    else
                        if parallelMode ==1
                            refFrame(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = int32(128);
                        else
                            refFrame = reconstructedY(:,:,currentFrameNum-1-MV(1,3));
                        end
                        thisBlock = int32(approximatedResidualBlock) + int32(refFrame(top + MV(1,1) : bottom + MV(1,1), left + MV(1,2) : right + MV(1,2)));
                    end

                    xMVMatrix = [xMVMatrix, left];
                    yMVMatrix = [yMVMatrix, top];
                    if FMEEnable
                        uMVMatrix = [uMVMatrix, MV(1,2)/2];
                        vMVMatrix = [vMVMatrix, MV(1,1)/2];
                    else
                        uMVMatrix = [uMVMatrix, MV(1,2)];
                        vMVMatrix = [vMVMatrix, MV(1,1)];
                    end

                    reconstructedFrame(top : bottom, left : right) = thisBlock;

                    encoderReference = encoderReferenceFrame(top : bottom, left : right);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    subBlockIndex = subBlockIndex + 1;
                else
                    % this block is splitted
                    approximatedResidualBlockTopLeft = decodeQTCCoeff(QTCCoeff, subBlockIndex, splitSize, smallBlockQP);
                    approximatedResidualBlockTopRight = decodeQTCCoeff(QTCCoeff, subBlockIndex + 1, splitSize, smallBlockQP);
                    approximatedResidualBlockBottomLeft = decodeQTCCoeff(QTCCoeff, subBlockIndex + 2, splitSize, smallBlockQP);
                    approximatedResidualBlockBottomRight = decodeQTCCoeff(QTCCoeff, subBlockIndex + 3, splitSize, smallBlockQP);

                    MVDiffTopLeft = MDiffRLEDecoded(1, subBlockIndex * 3 - 2 : subBlockIndex * 3);
                    MVDiffTopRight = MDiffRLEDecoded(1, (subBlockIndex + 1) * 3 - 2 : (subBlockIndex + 1) * 3);
                    MVDiffBottomLeft = MDiffRLEDecoded(1, (subBlockIndex + 2) * 3 - 2 : (subBlockIndex + 2) * 3);
                    MVDiffBottomRight = MDiffRLEDecoded(1, (subBlockIndex + 3) * 3 - 2 : (subBlockIndex + 3) * 3);

                    MVTopLeft = int32(previousMV) + int32(MVDiffTopLeft);
                    MVTopRight = int32(MVTopLeft) + int32(MVDiffTopRight);
                    MVBottomLeft = int32(MVTopRight) + int32(MVDiffBottomLeft);
                    MVBottomRight = int32(MVBottomLeft) + int32(MVDiffBottomRight);
                    previousMV = MVBottomRight;

                    if FMEEnable
                        if parallelMode == 1
                            FMEEnable = false;
                        else
                            refFrameTopLeft = interpolateRefFrames(:,:,currentFrameNum-1-MVTopLeft(1,3));
                            refFrameTopRight = interpolateRefFrames(:,:,currentFrameNum-1-MVTopRight(1,3));
                            refFrameBottomLeft = interpolateRefFrames(:,:,currentFrameNum-1-MVBottomLeft(1,3));
                            refFrameBottomRight = interpolateRefFrames(:,:,currentFrameNum-1-MVBottomRight(1,3));
                        end
                    else
                        if parallelMode == 1
                            refFrameTopLeft(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = int32(128);
                            refFrameTopRight(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = int32(128);
                            refFrameBottomLeft(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = int32(128);
                            refFrameBottomRight(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = int32(128);
                        else
                            refFrameTopLeft = reconstructedY(:,:,currentFrameNum-1-MVTopLeft(1,3));
                            refFrameTopRight = reconstructedY(:,:,currentFrameNum-1-MVTopRight(1,3));
                            refFrameBottomLeft = reconstructedY(:,:,currentFrameNum-1-MVBottomLeft(1,3));
                            refFrameBottomRight = reconstructedY(:,:,currentFrameNum-1-MVBottomRight(1,3));
                        end
                    end

                    % top left
                    if FMEEnable
                        if parallelMode == 1
                            FMEEnable = false;
                        else
                            thisBlock = int32(approximatedResidualBlockTopLeft) + ...
                                int32(refFrameTopLeft(2*top-1 + MVTopLeft(1,1) :2: 2*top-1 + MVTopLeft(1,1)+2*(splitSize-1), 2*left-1 + MVTopLeft(1,2) :2: 2*left-1 + MVTopLeft(1,2)+2*(splitSize-1)));
                        end
                    else
                        thisBlock = int32(approximatedResidualBlockTopLeft) + ...
                            int32(refFrameTopLeft(top + MVTopLeft(1,1) : top + splitSize - 1 + MVTopLeft(1,1), left + MVTopLeft(1,2) : left + splitSize - 1 + MVTopLeft(1,2)));
                    end

                    xMVMatrix = [xMVMatrix, left];
                    yMVMatrix = [yMVMatrix, top];
                    if FMEEnable
                        uMVMatrix = [uMVMatrix, MVTopLeft(1,2)/2];
                        vMVMatrix = [vMVMatrix, MVTopLeft(1,1)/2];
                    else
                        uMVMatrix = [uMVMatrix, MVTopLeft(1,2)];
                        vMVMatrix = [vMVMatrix, MVTopLeft(1,1)];
                    end

                    reconstructedFrame(top : top + splitSize - 1, left : left + splitSize - 1) = thisBlock;

                    encoderReference = encoderReferenceFrame(top : top + splitSize - 1, left : left + splitSize - 1);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    % top right

                    if FMEEnable
                        if parallelMode == 1
                            FMEEnable = false;
                        else
                            thisBlock = int32(approximatedResidualBlockTopRight) + ...
                                int32(refFrameTopRight(2*top-1 + MVTopRight(1,1) :2: 2*top-1 + MVTopRight(1,1)+2*(splitSize-1), 2*(left+splitSize)-1 + MVTopRight(1,2) :2: 2*(left+splitSize)-1 + MVTopRight(1,2)+2*(splitSize-1)));
                        end
                    else
                        thisBlock = int32(approximatedResidualBlockTopRight) + ...
                            int32(refFrameTopRight(top + MVTopRight(1,1) : top + splitSize - 1 + MVTopRight(1,1), left + splitSize + MVTopRight(1,2) : right + MVTopRight(1,2)));
                    end

                    xMVMatrix = [xMVMatrix, left + splitSize];
                    yMVMatrix = [yMVMatrix, top];
                    if FMEEnable
                        uMVMatrix = [uMVMatrix, MVTopRight(1,2)/2];
                        vMVMatrix = [vMVMatrix, MVTopRight(1,1)/2];
                    else
                        uMVMatrix = [uMVMatrix, MVTopRight(1,2)];
                        vMVMatrix = [vMVMatrix, MVTopRight(1,1)];
                    end

                    reconstructedFrame(top : top + splitSize - 1, left + splitSize : right) = thisBlock;

                    encoderReference = encoderReferenceFrame(top : top + splitSize - 1, left + splitSize : right);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    % bottom left

                    if FMEEnable
                        if parallelMode == 1
                            FMEEnable = false;
                        else
                            thisBlock = int32(approximatedResidualBlockBottomLeft) + ...
                                int32(refFrameBottomLeft(2*(top+splitSize)-1 + MVBottomLeft(1,1) :2: 2*(top+splitSize)-1 + MVBottomLeft(1,1)+2*(splitSize-1), 2*left-1 + MVBottomLeft(1,2) :2: 2*left-1 + MVBottomLeft(1,2)+2*(splitSize-1)));
                        end
                    else
                        thisBlock = int32(approximatedResidualBlockBottomLeft) + ...
                            int32(refFrameBottomLeft(top + splitSize + MVBottomLeft(1,1) : bottom + MVBottomLeft(1,1), left + MVBottomLeft(1,2) : left + splitSize - 1 + MVBottomLeft(1,2)));
                    end

                    xMVMatrix = [xMVMatrix, left];
                    yMVMatrix = [yMVMatrix, top + splitSize];
                    if FMEEnable
                        uMVMatrix = [uMVMatrix, MVBottomLeft(1,2)/2];
                        vMVMatrix = [vMVMatrix, MVBottomLeft(1,1)/2];
                    else
                        uMVMatrix = [uMVMatrix, MVBottomLeft(1,2)];
                        vMVMatrix = [vMVMatrix, MVBottomLeft(1,1)];
                    end

                    reconstructedFrame(top + splitSize : bottom, left : left + splitSize - 1) = thisBlock;

                    encoderReference = encoderReferenceFrame(top + splitSize : bottom, left : left + splitSize - 1);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    % bottom right

                    if FMEEnable
                        if parallelMode == 1
                            FMEEnable = false;
                        else
                            thisBlock = int32(approximatedResidualBlockBottomRight) + ...
                            int32(refFrameBottomRight(2*(top+splitSize)-1 + MVBottomRight(1,1) :2: 2*(top+splitSize)-1 + MVBottomRight(1,1)+2*(splitSize-1), 2*(left+splitSize)-1 + MVBottomRight(1,2) :2: 2*(left+splitSize)-1 + MVBottomRight(1,2)+2*(splitSize-1)));
                        end
                    else
                        thisBlock = int32(approximatedResidualBlockBottomRight) + ...
                            int32(refFrameBottomRight(top + splitSize + MVBottomRight(1,1) : bottom + MVBottomRight(1,1), left + splitSize + MVBottomRight(1,2) : right + MVBottomRight(1,2)));
                    end

                    xMVMatrix = [xMVMatrix, left + splitSize];
                    yMVMatrix = [yMVMatrix, top + splitSize];
                    if FMEEnable
                        uMVMatrix = [uMVMatrix, MVBottomRight(1,2)/2];
                        vMVMatrix = [vMVMatrix, MVBottomRight(1,1)/2];
                    else
                        uMVMatrix = [uMVMatrix, MVBottomRight(1,2)];
                        vMVMatrix = [vMVMatrix, MVBottomRight(1,1)];
                    end

                    reconstructedFrame(top + splitSize : bottom, left + splitSize : right) = thisBlock;

                    encoderReference = encoderReferenceFrame(top + splitSize : bottom, left + splitSize : right);
                    if isequal(thisBlock, encoderReference) == false
                        disp("bad!");
                    end

                    subBlockIndex = subBlockIndex + 4;
                end
            end
        end
    end
    reconstructedY(:,:,currentFrameNum) = reconstructedFrame;

    if FMEEnable == true
        if parallelMode == 1
            FMEEnable = false;
        else
            interpolateRefFrames(:,:,currentFrameNum) = interpolateFrames(reconstructedY(:,:,currentFrameNum));
        end
    end

    xCell{currentFrameNum} = xMVMatrix;
    yCell{currentFrameNum} = yMVMatrix;
    uCell{currentFrameNum} = uMVMatrix;
    vCell{currentFrameNum} = vMVMatrix;

end

splitPercentage = totalSplit / double((widthBlockNum * heightBlockNum * nFrame));

if visualizeVBS
    reconstructedY = addFramesToVisualizeVBS(reconstructedY, nFrame, width, height, blockSize, splits);
end

plotRGB(uint8(reconstructedY(1:height, 1:width, :)), nFrame, DecoderOutputPath, refFrameMatrix, blockSize, visualizeNRF, visualizeRGB);

if visualizeMM
    R = reconstructedY(1:height, 1:width, :);
    G = reconstructedY(1:height, 1:width, :);
    B = reconstructedY(1:height, 1:width, :);

    for i=1:nFrame
        x = xCell{i};
        y = yCell{i};
        u = uCell{i};
        v = vCell{i};
        backgroundFileName = DecoderOutputPath + sprintf("%04d",i) + ".png";
        MVOutputFileName = DecoderOutputPath + "MM_" + sprintf("%04d",i) + ".jpeg";
        quiver(axes(), x,y,u,v);
        axis tight;
        set(gca,'YDir','reverse');
        set(gca,'XTick',[],'YTick',[]);
        hold on
        I = imread(backgroundFileName);
        h = image(xlim,ylim,I);
        uistack(h,'bottom')
        saveas(gcf, fullfile(MVOutputFileName));
    end
end

generateYOnlyVideo(uint8(reconstructedY(1:height, 1:width, :)), nFrame, ['DecoderOutput' filesep 'outputYUV.yuv']);

end

function approximatedResidualBlock = decodeQTCCoeff(QTCCoeff, subBlockIndex, blockSize, QP)
encodedQuantizedBlock = QTCCoeff(1, subBlockIndex);
encodedRLE = expGolombDecoding(convertStringsToChars(encodedQuantizedBlock));
scanned = reverseRLE(encodedRLE, blockSize * blockSize);
quantizedBlock = reverseScannedBlock(scanned, blockSize);
rescaledBlock = rescaling(quantizedBlock, QP);
approximatedResidualBlock = idct2(rescaledBlock);
end

function [numSplitted, numNonSplitted] = countSplitted(splitRLEDecoded, widthBlockNum, heightBlockNum)
numSplitted = 0;
numNonSplitted = 0;

for heightBlockIndex = 1:heightBlockNum
    for widthBlockIndex = 1:widthBlockNum
        if splitRLEDecoded(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex)
            numSplitted = numSplitted + 1;
        else
            numNonSplitted = numNonSplitted + 1;
        end
    end
end
end

function reconstructedY = addFramesToVisualizeVBS(reconstructedY, nFrame, width, height, blockSize, splits)
widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');
splitSize = blockSize / 2;

for currentFrameNum = 1:nFrame
    splitSequence = splits(currentFrameNum, 1);
    splitFrame = expGolombDecoding(convertStringsToChars(splitSequence));
    splitRLEDecoded = reverseRLE(splitFrame, widthBlockNum * heightBlockNum);
    for heightBlockIndex = 1:heightBlockNum
        for widthBlockIndex = 1:widthBlockNum
            top = int32((heightBlockIndex-1)*blockSize + 1);
            bottom = int32(heightBlockIndex * blockSize);
            left = int32((widthBlockIndex-1) * blockSize + 1);
            right = int32(widthBlockIndex * blockSize);

            if splitRLEDecoded(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex)
                reconstructedY(top : top + splitSize - 1, left : left + splitSize - 1, currentFrameNum) = addFrame(reconstructedY(top : top + splitSize - 1, left : left + splitSize - 1, currentFrameNum), heightBlockIndex == 1, widthBlockIndex == 1);
                reconstructedY(top : top + splitSize - 1, left + splitSize : right, currentFrameNum) = addFrame(reconstructedY(top : top + splitSize - 1, left + splitSize : right, currentFrameNum), heightBlockIndex == 1, false);
                reconstructedY(top + splitSize : bottom, left : left + splitSize - 1, currentFrameNum) = addFrame(reconstructedY(top + splitSize : bottom, left : left + splitSize - 1, currentFrameNum), false, widthBlockIndex == 1);
                reconstructedY(top + splitSize : bottom, left + splitSize : right, currentFrameNum) = addFrame(reconstructedY(top + splitSize : bottom, left + splitSize : right, currentFrameNum), false, false);
            else
                reconstructedY(top : bottom, left : right, currentFrameNum) = addFrame(reconstructedY(top : bottom, left : right, currentFrameNum), heightBlockIndex == 1, widthBlockIndex == 1);
            end
        end
    end
end
end

function block = addFrame(block, addTop, addLeft)
height = size(block, 1);
width = size(block, 2);

if addLeft
    block(1:height, 1) = 0;
end

block(1:height, width) = 0;
if addTop
    block(1, 1:width) = 0;
end
block(height, 1:width) = 0;
end

function plotRGB(Y, nFrame, rgbOutputPath, refFrameMatrix, blockSize, visualizeNRF, visualizeRGB)
height = size(Y,1);
width = size(Y,2);
R = Y;
G = Y;
B = Y;

if visualizeRGB
    for i=1:nFrame
        im(:,:,1)=R(:,:,i);
        im(:,:,2)=G(:,:,i);
        im(:,:,3)=B(:,:,i);
        imwrite(uint8(im),[rgbOutputPath, sprintf('%04d',i), '.png']);
    end
end

if visualizeNRF

    widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
    heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

    for currentFrameNum = 1:nFrame
        for heightBlockIndex = 1:heightBlockNum
            for widthBlockIndex = 1:widthBlockNum
                top = int32((heightBlockIndex-1)*blockSize + 1);
                bottom = int32(heightBlockIndex * blockSize);
                left = int32((widthBlockIndex-1) * blockSize + 1);
                right = int32(widthBlockIndex * blockSize);
                if refFrameMatrix(heightBlockIndex, widthBlockIndex, currentFrameNum) == 1
                    G(top:bottom, left:right, currentFrameNum) = 0;
                    B(top:bottom, left:right, currentFrameNum) = 0;
                elseif refFrameMatrix(heightBlockIndex, widthBlockIndex, currentFrameNum) == 2
                    R(top:bottom, left:right, currentFrameNum) = 0;
                    B(top:bottom, left:right, currentFrameNum) = 0;
                elseif refFrameMatrix(heightBlockIndex, widthBlockIndex, currentFrameNum) == 3
                    G(top:bottom, left:right, currentFrameNum) = 0;
                    R(top:bottom, left:right, currentFrameNum) = 0;
                end
            end
        end
    end

    for i=1:nFrame
        nRefFramesOutputPath = rgbOutputPath + "nRefFrames_" + sprintf("%04d",i) + ".png";
        im(:,:,1)=R(:,:,i);
        im(:,:,2)=G(:,:,i);
        im(:,:,3)=B(:,:,i);
        imwrite(uint8(im),nRefFramesOutputPath);
    end

end
end

function generateYOnlyVideo(Y, nFrame, YUVOutputPath)
fid = createOrClearFile(YUVOutputPath);
for i=1:nFrame
    fwrite(fid,uint8(Y(:,:,i)'),'uchar');
end
fclose(fid);
end

function QPDiffFrame = decodeQPFrame(QPFrame, heightBlockNum)
    % Decode QP frame
    QPDiffFrame = reverseRLE(expGolombDecoding(convertStringsToChars(QPFrame)), heightBlockNum + 1);
    QPDiffFrame = QPDiffFrame(1, 2:end); % Remove first bit (I/P frame indicator)
end

function splitFrame = decodeSplitFrame(splitSequence, widthBlockNum, heightBlockNum, VBSEnable)
    if VBSEnable
        splitFrame = expGolombDecoding(convertStringsToChars(splitSequence));
        splitFrame = reverseRLE(splitFrame, widthBlockNum * heightBlockNum);
    else
        splitFrame = zeros(1, widthBlockNum * heightBlockNum);
    end
end

function reconstructedY = combineParallelResults(reconstructedYDist)
    reconstructedY = gather(reconstructedYDist);
end

function reconstructedFrame = reconstructFrame(QTCCoeff, MDiffFrame, splitFrame, QPDiffFrame, widthBlockNum, heightBlockNum, blockSize, VBSEnable, FMEEnable)
    % Initialize the reconstructed frame
    reconstructedFrame = int32(zeros(heightBlockNum * blockSize, widthBlockNum * blockSize));
    subBlockIndex = 1; % Index to track the sub-block within QTCCoeff
    previousQP = 6; % Initial QP value

    for heightBlockIndex = 1:heightBlockNum
        currentQP = int32(QPDiffFrame(heightBlockIndex)) + int32(previousQP);
        previousQP = currentQP; % Update QP for next block

        for widthBlockIndex = 1:widthBlockNum
            % Calculate the position of the current block
            top = int32((heightBlockIndex-1)*blockSize + 1);
            bottom = int32(heightBlockIndex * blockSize);
            left = int32((widthBlockIndex-1) * blockSize + 1);
            right = int32(widthBlockIndex * blockSize);

            % Process block based on split decision
            if VBSEnable && splitFrame(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex)
                % Handle split blocks
                [reconstructedBlock, subBlockIndex] = processSplitBlock(QTCCoeff, MDiffFrame, subBlockIndex, blockSize, currentQP, top, left);
            else
                % Handle non-split blocks
                [reconstructedBlock, subBlockIndex] = processNonSplitBlock(QTCCoeff, MDiffFrame, subBlockIndex, blockSize, currentQP);
            end

            % Update the reconstructed frame with the processed block
            reconstructedFrame(top:bottom, left:right) = reconstructedBlock;
        end
    end
end

function [reconstructedBlock, subBlockIndex] = processSplitBlock(QTCCoeff, MDiffFrame, subBlockIndex, blockSize, currentQP, top, left)
    % Function to process a split block
    splitSize = blockSize / 2;
    
    % Initialize the reconstructed block
    reconstructedBlock = int32(zeros(blockSize, blockSize));

    % Process each of the four sub-blocks
    for subBlockNum = 1:4
        % Decode the QTCCoeff for the current sub-block
        encodedQuantizedBlock = QTCCoeff(1, subBlockIndex);
        approximatedResidualBlock = decodeQTCCoeff(encodedQuantizedBlock, splitSize, currentQP);

        % Place the reconstructed sub-block in the correct position
        switch subBlockNum
            case 1 % Top-left
                reconstructedBlock(1:splitSize, 1:splitSize) = approximatedResidualBlock;
            case 2 % Top-right
                reconstructedBlock(1:splitSize, splitSize+1:end) = approximatedResidualBlock;
            case 3 % Bottom-left
                reconstructedBlock(splitSize+1:end, 1:splitSize) = approximatedResidualBlock;
            case 4 % Bottom-right
                reconstructedBlock(splitSize+1:end, splitSize+1:end) = approximatedResidualBlock;
        end

        % Increment the subBlockIndex
        subBlockIndex = subBlockIndex + 1;
    end

    % Return the reconstructed block and updated subBlockIndex
    return;
end

function [reconstructedBlock, subBlockIndex] = processNonSplitBlock(QTCCoeff, MDiffFrame, subBlockIndex, blockSize, currentQP)
    % Function to process non-split block
    % Decode the QTCCoeff for the current block
    encodedQuantizedBlock = QTCCoeff(1, subBlockIndex);
    approximatedResidualBlock = decodeQTCCoeff(encodedQuantizedBlock, blockSize, currentQP);

    % Implement logic for processing non-split blocks (e.g., IDCT)
    reconstructedBlock = idct2(approximatedResidualBlock);
    
    % Increment subBlockIndex
    subBlockIndex = subBlockIndex + 1;

    % Return the reconstructed block and updated subBlockIndex
    return
end

