function decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, encoderReconstructedY)
    DecoderOutputPath = 'DecoderOutput\';
    reconstructedY = zeros(height, width, nFrame);
    
    if ~exist(DecoderOutputPath,'dir')
        mkdir(DecoderOutputPath)
    end
    
    widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
    heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');
    
    splitSize = blockSize / 2;
    smallBlockQP = QP - 1;
    if smallBlockQP < 0
        smallBlockQP = 0; 
    end
    
    for currentFrameNum = 1:nFrame
        QTCCoeff = QTCCoeffs(currentFrameNum, :);
        MDiff = MDiffs(currentFrameNum, 1);

        MDiffFrame = expGolombDecoding(convertStringsToChars(MDiff));
        
        if VBSEnable
            splitSequence = splits(currentFrameNum, 1);
            splitFrame = expGolombDecoding(convertStringsToChars(splitSequence));
            splitRLEDecoded = reverseRLE(splitFrame, widthBlockNum * heightBlockNum);
            [numSplitted, numNonSplitted] = countSplitted(splitRLEDecoded, widthBlockNum, heightBlockNum);
        else
            numSplitted = 0;
            numNonSplitted = widthBlockNum * heightBlockNum;
        end
        
        reconstructedFrame(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = int32(128);
        
        encoderReferenceFrame = encoderReconstructedY(:, :, currentFrameNum);
            
        if rem(currentFrameNum,I_Period) == 1 || I_Period == 1
            % I frame
            MDiffRLEDecoded = reverseRLE(MDiffFrame, numNonSplitted + numSplitted * 4);
            
            subBlockIndex = 1;
            for heightBlockIndex = 1:heightBlockNum
                previousMode = int32(0); % assume horizontal in the beginning
                for widthBlockIndex = 1:widthBlockNum
                    [verticalReference, horizontalReference] = getIntraPredictionReference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize);
                    top = int32((heightBlockIndex-1)*blockSize + 1);
                    bottom = int32(heightBlockIndex * blockSize);
                    left = int32((widthBlockIndex-1) * blockSize + 1);
                    right = int32(widthBlockIndex * blockSize);
                    
                    if VBSEnable == false || splitRLEDecoded(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex) == false
                        % do not split this block
                        approximatedResidualBlock = decodeQTCCoeff(QTCCoeff, subBlockIndex, blockSize, QP);

                        notSameMode = MDiffRLEDecoded(1, subBlockIndex); % 0 = no change, 1 = changed
                        mode = xor(previousMode, notSameMode);
                        previousMode = mode;

                        if mode == 0
                            % vertical
                            thisBlock = int32(approximatedResidualBlock) + int32(verticalReference);
                        else
                            % horizontal
                            thisBlock = int32(approximatedResidualBlock) + int32(horizontalReference);
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
                        else
                            % horizontal
                            thisBlock = int32(approximatedResidualBlockTopLeft) + int32(horizontalReference(1:splitSize, 1));
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
                        else
                            % horizontal
                            thisBlock = int32(approximatedResidualBlockTopRight) + int32(reconstructedFrame(top : top + splitSize - 1, left + splitSize - 1));
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
                        else
                            % horizontal
                            thisBlock = int32(approximatedResidualBlockBottomLeft) + int32(horizontalReference(splitSize+1:2*splitSize, 1));
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
                        else
                            % horizontal
                            thisBlock = int32(approximatedResidualBlockBottomRight) + int32(reconstructedFrame(top + splitSize : bottom, left + splitSize - 1));
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
            for heightBlockIndex = 1:heightBlockNum
                previousMV = int32([0, 0, 0]);
                for widthBlockIndex = 1:widthBlockNum
                    top = int32((heightBlockIndex-1)*blockSize + 1);
                    bottom = int32(heightBlockIndex * blockSize);
                    left = int32((widthBlockIndex-1) * blockSize + 1);
                    right = int32(widthBlockIndex * blockSize);
                    
                    if VBSEnable == false || splitRLEDecoded(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex) == false
                        % do not split this block
                        approximatedResidualBlock = decodeQTCCoeff(QTCCoeff, subBlockIndex, blockSize, QP);

                        MVDiff = MDiffRLEDecoded(1, subBlockIndex * 3 - 2 : subBlockIndex * 3);
                        MV = int32(previousMV) + int32(MVDiff);
                        previousMV = MV;
                        refFrame = reconstructedY(:,:,currentFrameNum-1-MV(1,3));
                        thisBlock = int32(approximatedResidualBlock) + int32(refFrame(top + MV(1,1) : bottom + MV(1,1), left + MV(1,2) : right + MV(1,2)));
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
                        
                        refFrameTopLeft = reconstructedY(:,:,currentFrameNum-1-MVTopLeft(1,3));
                        refFrameTopRight = reconstructedY(:,:,currentFrameNum-1-MVTopRight(1,3));
                        refFrameBottomLeft = reconstructedY(:,:,currentFrameNum-1-MVBottomLeft(1,3));
                        refFrameBottomRight = reconstructedY(:,:,currentFrameNum-1-MVBottomRight(1,3));
                        
                        % top left
                        thisBlock = int32(approximatedResidualBlockTopLeft) + ...
                            int32(refFrameTopLeft(top + MVTopLeft(1,1) : top + splitSize - 1 + MVTopLeft(1,1), left + MVTopLeft(1,2) : left + splitSize - 1 + MVTopLeft(1,2)));
                        reconstructedFrame(top : top + splitSize - 1, left : left + splitSize - 1) = thisBlock;

                        encoderReference = encoderReferenceFrame(top : top + splitSize - 1, left : left + splitSize - 1);
                        if isequal(thisBlock, encoderReference) == false
                            disp("bad!");
                        end
                        
                        % top right                        
                        thisBlock = int32(approximatedResidualBlockTopRight) + ...
                            int32(refFrameTopRight(top + MVTopRight(1,1) : top + splitSize - 1 + MVTopRight(1,1), left + splitSize + MVTopRight(1,2) : right + MVTopRight(1,2)));
                        reconstructedFrame(top : top + splitSize - 1, left + splitSize : right) = thisBlock;

                        encoderReference = encoderReferenceFrame(top : top + splitSize - 1, left + splitSize : right);
                        if isequal(thisBlock, encoderReference) == false
                            disp("bad!");
                        end
                        
                        % bottom left
                        thisBlock = int32(approximatedResidualBlockBottomLeft) + ...
                            int32(refFrameBottomLeft(top + splitSize + MVBottomLeft(1,1) : bottom + MVBottomLeft(1,1), left + MVBottomLeft(1,2) : left + splitSize - 1 + MVBottomLeft(1,2)));
                        reconstructedFrame(top + splitSize : bottom, left : left + splitSize - 1) = thisBlock;

                        encoderReference = encoderReferenceFrame(top + splitSize : bottom, left : left + splitSize - 1);
                        if isequal(thisBlock, encoderReference) == false
                            disp("bad!");
                        end
                        
                        % bottom right
                        thisBlock = int32(approximatedResidualBlockBottomRight) + ...
                            int32(refFrameBottomRight(top + splitSize + MVBottomRight(1,1) : bottom + MVBottomRight(1,1), left + splitSize + MVBottomRight(1,2) : right + MVBottomRight(1,2)));
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

        % get YOnly vedio
        YOnlyFilePath = [DecoderOutputPath, sprintf('%04d',currentFrameNum), '.yuv'];
        fid = createOrClearFile(YOnlyFilePath);
        fwrite(fid,uint8(reconstructedFrame(1:height,1:width)),'uchar');
        fclose(fid);
        
        YOnlyFilePath = [DecoderOutputPath, sprintf('%04d',currentFrameNum), '.csv'];
        fid = createOrClearFile(YOnlyFilePath);
        writematrix(uint8(reconstructedFrame(1:height,1:width)), YOnlyFilePath);
        fclose(fid);
    end
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