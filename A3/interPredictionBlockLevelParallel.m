function [QTCCoeffsFrame, MDiffsFrame, splitFrame, QPFrame, reconstructedFrame] = ...
        interPredictionBlockLevelParallel(height, width, heightBlockNum, widthBlockNum, refFrames, interpolateRefFrames, currentFrame, r, blockSize, QP, VBSEnable, FMEEnable, FastME, Lambda, RCFlag)
    spmd(2)
        if spmdIndex == 1
            reconstructedFrameWorker = int32(zeros(height, width));
            QTCCoeffsFrameRow = cell(heightBlockNum, 1);
            MDiffsIntRow = cell(heightBlockNum, 1);
            splitIntRow = zeros(heightBlockNum, widthBlockNum);
            for heightBlockIndex = 1:2:heightBlockNum
                previousMV = int32([0, 0, 0]);
                QTCCoeffsFrameRow{heightBlockIndex, 1} = strings(0);

                for widthBlockIndex = 1:widthBlockNum
                    [split, bestMV, encodedQuantizedBlock, reconstructedBlock] = interPredictBlock( ...
                        refFrames, interpolateRefFrames, currentFrame, widthBlockIndex, heightBlockIndex, ...
                        r, blockSize, QP, VBSEnable, FMEEnable, FastME, previousMV, Lambda, RCFlag, false);
                    
                    splitIntRow(heightBlockIndex, widthBlockIndex) = split;
                    QTCCoeffsFrameRow{heightBlockIndex, 1} = [QTCCoeffsFrameRow{heightBlockIndex, 1}, encodedQuantizedBlock];
                    if VBSEnable && split
                        for i = 1:4
                            MDiffsIntRow{heightBlockIndex, 1} = [MDiffsIntRow{heightBlockIndex, 1}, bestMV(i, :) - previousMV];
                            previousMV = bestMV(i, :);
                        end
                    else
                        % Differential encoding
                        MDiffsIntRow{heightBlockIndex, 1} = [MDiffsIntRow{heightBlockIndex, 1}, bestMV - previousMV];
                        previousMV = bestMV;
                    end
                    reconstructedFrameWorker( ...
                        (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, ...
                        (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize ...
                        ) = reconstructedBlock;
                end
            end
        elseif spmdIndex == 2
            reconstructedFrameWorker = int32(zeros(height, width));
            QTCCoeffsFrameRow = cell(heightBlockNum, 1);
            MDiffsIntRow = cell(heightBlockNum, 1);
            splitIntRow = zeros(heightBlockNum, widthBlockNum);
            for heightBlockIndex = 2:2:heightBlockNum
                previousMV = int32([0, 0, 0]);
                QTCCoeffsFrameRow{heightBlockIndex, 1} = strings(0);

                for widthBlockIndex = 1:widthBlockNum
                    [split, bestMV, encodedQuantizedBlock, reconstructedBlock] = interPredictBlock( ...
                        refFrames, interpolateRefFrames, currentFrame, widthBlockIndex, heightBlockIndex, ...
                        r, blockSize, QP, VBSEnable, FMEEnable, FastME, previousMV, Lambda, RCFlag, false);
                    
                    splitIntRow(heightBlockIndex, widthBlockIndex) = split;
                    QTCCoeffsFrameRow{heightBlockIndex, 1} = [QTCCoeffsFrameRow{heightBlockIndex, 1}, encodedQuantizedBlock];
                    if VBSEnable && split
                        for i = 1:4
                            MDiffsIntRow{heightBlockIndex, 1} = [MDiffsIntRow{heightBlockIndex, 1}, bestMV(i, :) - previousMV];
                            previousMV = bestMV(i, :);
                        end
                    else
                        % Differential encoding
                        MDiffsIntRow{heightBlockIndex, 1} = [MDiffsIntRow{heightBlockIndex, 1}, bestMV - previousMV];
                        previousMV = bestMV;
                    end
                    reconstructedFrameWorker( ...
                        (heightBlockIndex-1)*blockSize+1 : heightBlockIndex*blockSize, ...
                        (widthBlockIndex-1)*blockSize+1 : widthBlockIndex*blockSize ...
                        ) = reconstructedBlock;
                end
            end
        end
    end

    % end of spmd region, gather results in order
    QTCCoeffsFrame = strings(0);
    MDiffsInt = [];
    splitInt = [];
    QPInt = [1]; % encode the first bit as 1 to signify this is an P-frame
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