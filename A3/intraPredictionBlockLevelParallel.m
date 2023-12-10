function [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame] = ...
        intraPredictionBlockLevelParallel(height, width, heightBlockNum, widthBlockNum, currentFrame, blockSize, QP, VBSEnable, FMEEnable, FastME, Lambda, RCFlag)
    spmd(2)
        if spmdIndex == 1
            reconstructedFrameWorker = int32(zeros(height, width));
            QTCCoeffsFrameRow = cell(heightBlockNum, 1);
            MDiffsIntRow = cell(heightBlockNum, 1);
            splitIntRow = zeros(heightBlockNum, widthBlockNum);

            for heightBlockIndex = 1:2:heightBlockNum
                previousMode = int32(0);
                QTCCoeffsFrameRow{heightBlockIndex, 1} = strings(0);
                
                % if this is not the first row, get the reconstructed row
                % from the other worker
                if heightBlockIndex > 1
                    reconstructedRow = spmdReceive;
                    reconstructedFrameWorker((heightBlockIndex-2)*blockSize+1 : (heightBlockIndex-1)*blockSize, :) = reconstructedRow;
                end

                for widthBlockIndex = 1:widthBlockNum
                    currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);
                    % the left-𝑖 (or top-𝑖) border reconstructed samples
                    [verticalRefernce, horizontalReference] = getIntraPredictionReference( ...
                        heightBlockIndex, widthBlockIndex, reconstructedFrameWorker, blockSize ...
                        );
                    [split, mode, encodedQuantizedBlock, reconstructedBlock] = intraPredictBlock( ...
                        verticalRefernce, horizontalReference, currentBlock, blockSize, ...
                        QP, previousMode, VBSEnable, FMEEnable, FastME, Lambda, RCFlag, false);

                    splitIntRow(heightBlockIndex, widthBlockIndex) = split;
                    QTCCoeffsFrameRow{heightBlockIndex, 1} = [QTCCoeffsFrameRow{heightBlockIndex, 1}, encodedQuantizedBlock];
                    if VBSEnable && split
                        for i = 1:4
                            MDiffsIntRow{heightBlockIndex, 1} = [MDiffsIntRow{heightBlockIndex, 1}, xor(mode(1, i), previousMode)];
                            previousMode = mode(1, i);
                        end
                    else
                        % Differential encoding
                        MDiffsIntRow{heightBlockIndex, 1} = [MDiffsIntRow{heightBlockIndex, 1}, xor(mode, previousMode)];
                        previousMode = mode;
                    end
                    reconstructedFrameWorker( ...
                        (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, ...
                        (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize ...
                        ) = reconstructedBlock;

                    spmdSend(reconstructedBlock, 2);
                end
            end
            % just receive the last row
            spmdReceive;
        elseif spmdIndex == 2
            reconstructedFrameWorker = int32(zeros(height, width));
            QTCCoeffsFrameRow = cell(heightBlockNum, 1);
            MDiffsIntRow = cell(heightBlockNum, 1);
            splitIntRow = zeros(heightBlockNum, widthBlockNum);

            for heightBlockIndex = 2:2:heightBlockNum
                previousMode = int32(0);
                QTCCoeffsFrameRow{heightBlockIndex, 1} = strings(0);

                for widthBlockIndex = 1:widthBlockNum
                    otherWorkerData = spmdReceive;
                    reconstructedFrameWorker( ...
                        (heightBlockIndex-2)*blockSize+1 : (heightBlockIndex-1)*blockSize, ...
                        (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize ...
                        ) = otherWorkerData;

                    currentBlock = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, currentFrame,0,0);
                    % the left-𝑖 (or top-𝑖) border reconstructed samples
                    [verticalRefernce, horizontalReference] = getIntraPredictionReference( ...
                        heightBlockIndex, widthBlockIndex, reconstructedFrameWorker, blockSize ...
                        );
                    [split, mode, encodedQuantizedBlock, reconstructedBlock] = intraPredictBlock( ...
                        verticalRefernce, horizontalReference, currentBlock, blockSize, ...
                        QP, previousMode, VBSEnable, FMEEnable, FastME, Lambda, RCFlag, false);

                    splitIntRow(heightBlockIndex, widthBlockIndex) = split;
                    QTCCoeffsFrameRow{heightBlockIndex, 1} = [QTCCoeffsFrameRow{heightBlockIndex, 1}, encodedQuantizedBlock];
                    if VBSEnable && split
                        for i = 1:4
                            MDiffsIntRow{heightBlockIndex, 1} = [MDiffsIntRow{heightBlockIndex, 1}, xor(mode(1, i), previousMode)];
                            previousMode = mode(1, i);
                        end
                    else
                        % Differential encoding
                        MDiffsIntRow{heightBlockIndex, 1} = [MDiffsIntRow{heightBlockIndex, 1}, xor(mode, previousMode)];
                        previousMode = mode;
                    end
                    reconstructedFrameWorker( ...
                        (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, ...
                        (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize ...
                        ) = reconstructedBlock;
                end
                % need to update worker 1
                spmdSend(reconstructedFrameWorker((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize,:), 1);
            end
        end
    end

    % end of spmd region, gather results in order
    QTCCoeffsFrame = strings(0);
    MDiffsInt = [];
    splitInt = [];
    QPInt = [0]; % encode the first bit as 0 to signify this is an I-frame
    previousQP = 6;

    reconstructedFrame = int32(zeros(height, width));
    for heightBlockIndex = 1:heightBlockNum
        if mod(heightBlockIndex, 2) == 1
            % first worker
            QTCCoeffsFrame = [QTCCoeffsFrame, QTCCoeffsFrameRow{1}{heightBlockIndex, 1}];
            MDiffsInt = [MDiffsInt, MDiffsIntRow{1}{heightBlockIndex, 1}];
            splitInt = [splitInt, splitIntRow{1}(heightBlockIndex, :)];
            QPInt = [QPInt, QP - previousQP];
            previousQP = QP;

            reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, :) = reconstructedFrameWorker{1}((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, :);
        else
            % second worker
            QTCCoeffsFrame = [QTCCoeffsFrame, QTCCoeffsFrameRow{2}{heightBlockIndex, 1}];
            MDiffsInt = [MDiffsInt, MDiffsIntRow{2}{heightBlockIndex, 1}];
            splitInt = [splitInt, splitIntRow{2}(heightBlockIndex, :)];
            QPInt = [QPInt, QP - previousQP];
            previousQP = QP;

            reconstructedFrame((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, :) = reconstructedFrameWorker{2}((heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, :);
        end
    end

    MDiffRLE = RLE(MDiffsInt);
    MDiffsFrame = expGolombEncoding(MDiffRLE);

    splitRLE = RLE(splitInt);
    splitFrame = expGolombEncoding(splitRLE);

    QPRLE = RLE(QPInt);
    QPFrame = expGolombEncoding(QPRLE);
end