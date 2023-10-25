function ex4_decoder(nFrame, width, height, blockSize, QP, I_Period, QTCCoeffs, MDiffs)
    MVOutputPath = 'MVOutput\';
    ResidualOutputPath = 'approximatedResidualOutput\';
    assert(exist(MVOutputPath,'dir') > 0);
    assert(exist(ResidualOutputPath,'dir') > 0);
    
    DecoderOutputPath = 'DecoderOutput\';
    
    if ~exist(DecoderOutputPath,'dir')
        mkdir(DecoderOutputPath)
    end
    
    widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
    heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');
    
    for currentFrameNum = 1:nFrame
        QTCCoeff = QTCCoeffs(currentFrameNum, :);
        MDiff = MDiffs(currentFrameNum, 1);

        MDiffFrame = expGolombDecoding(convertStringsToChars(MDiff));
        
        reconstructedFrame(1:heightBlockNum*blockSize,1:widthBlockNum*blockSize) = uint8(128);
            
        if rem(currentFrameNum,I_Period) == 1
            % I frame
            MDiffRLEDecoded = reverseRLE(MDiffFrame, widthBlockNum * heightBlockNum);
            for heightBlockIndex = 1:heightBlockNum
                previousMode = int32(0); % assume horizontal in the beginning
                for widthBlockIndex = 1:widthBlockNum
                    encodedQuantizedBlock = QTCCoeff(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex);
                    encodedRLE = expGolombDecoding(convertStringsToChars(encodedQuantizedBlock));
                    scanned = reverseRLE(encodedRLE, blockSize * blockSize);
                    quantizedBlock = reverseScannedBlock(scanned, blockSize);
                    rescaledBlock = rescaling(quantizedBlock, QP);
                    approximatedResidualBlock = idct2(rescaledBlock);
                    
                    notSameMode = MDiffRLEDecoded(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex); % 0 = no change, 1 = changed
                    mode = xor(previousMode, notSameMode);
                    previousMode = mode;
                    
                    [verticalRefernce, horizontalReference] = getIntraPredictionReference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize);
                    
                    if mode == 0
                        % horizontal
                        thisBlock = int32(approximatedResidualBlock) + int32(horizontalReference);
                    else
                        % vertical
                        thisBlock = int32(approximatedResidualBlock) + int32(verticalRefernce);
                    end
                    reconstructedFrame((heightBlockIndex-1)*blockSize + 1 : heightBlockIndex * blockSize, (widthBlockIndex-1) * blockSize + 1 : widthBlockIndex * blockSize) = thisBlock;
                end
            end
        else
            % P frame
            MDiffRLEDecoded = reverseRLE(MDiffFrame, widthBlockNum * heightBlockNum * 2);
            for heightBlockIndex = 1:heightBlockNum
                previousMV = int32([0, 0]); % assume horizontal in the beginning
                for widthBlockIndex = 1:widthBlockNum
                    encodedQuantizedBlock = QTCCoeff(1, (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex);
                    encodedRLE = expGolombDecoding(convertStringsToChars(encodedQuantizedBlock));
                    scanned = reverseRLE(encodedRLE, blockSize * blockSize);
                    quantizedBlock = reverseScannedBlock(scanned, blockSize);
                    rescaledBlock = rescaling(quantizedBlock, QP);
                    approximatedResidualBlock = idct2(rescaledBlock);
                    
                    blockNum = (heightBlockIndex - 1) * widthBlockNum + widthBlockIndex;
                    MVDiff = MDiffRLEDecoded(1, blockNum * 2 - 1 : blockNum * 2);
                    MV = int32(previousMV) + int32(MVDiff);
                    previousMV = MV;
                    
                    top = int32((heightBlockIndex-1)*blockSize + 1);
                    bottom = int32(heightBlockIndex * blockSize);
                    left = int32((widthBlockIndex-1) * blockSize + 1);
                    right = int32(widthBlockIndex * blockSize);
                    thisBlock = int32(approximatedResidualBlock) + int32(refFrame(top + MV(1,2) : bottom + MV(1,2), left + MV(1,1) : right + MV(1,1)));
                    reconstructedFrame(top : bottom, left : right) = thisBlock;
                end
            end
        end
        refFrame = reconstructedFrame;
        
        YOnlyFilePath = [DecoderOutputPath, sprintf('%04d',currentFrameNum), '.yuv'];
        fid = createOrClearFile(YOnlyFilePath);
        fwrite(fid,uint8(reconstructedFrame(1:height,1:width)),'uchar');
        fclose(fid);
    end
end