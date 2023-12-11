classdef vbsFrame
    %reconstructedFrame Summary of this class goes here
    properties
        referenceFrames;
        splitStr;
        entropyedMV;
        entropyedResidual;
        width;
        height;
        blockSize;
        QP;
        isDifferential;
        nRefFrames;
        FMEEnable;
    end

    methods
        function obj = vbsFrame(referenceFrames, splitStr, entropyedMV, ...
                            entropyedResidual, width, height, blockSize, ...
                            QP, isDifferential, nRefFrames, FMEEnable)
            obj.referenceFrames = referenceFrames;
            obj.splitStr = splitStr;
            obj.entropyedMV = entropyedMV;
            obj.entropyedResidual = entropyedResidual;
            obj.width = width;
            obj.height = height;
            obj.blockSize = blockSize;
            obj.QP = QP;
            obj.isDifferential = isDifferential;
            obj.nRefFrames = nRefFrames;
            obj.FMEEnable = FMEEnable;
        end

        function [coloredY, reconstructedY, QPs] = reconstructedFrameWithQP(obj, previousQPs)
            coloredY = {};
            reconstructedY = {};
            startIdx = 1;
            splitBlocks = obj.getSplitStrBlocks();
            xBlocks = obj.width / obj.blockSize;
            if obj.nRefFrames > 1
                mvL = 3;
            else
                mvL = 2;
            end
            QPs = [];
            for x = 1 : obj.height / obj.blockSize
                prevQP = previousQPs(x);
                currQP = prevQP;
                previousMV = zeros(1, mvL);
                for y = 1 : obj.width / obj.blockSize
                    splitS = cell2mat(splitBlocks((x - 1) * xBlocks + y));
                    mv = entropy(obj.entropyedMV{x, y}, obj.blockSize).decode(0);
                    residual = entropy(obj.entropyedResidual{x, y}, obj.blockSize).decode(0);
                    if y == 1
                        currQP = residual(1) + prevQP;
                        residual = residual(2 : end);
                        QPs = [QPs, currQP];
                    end
                    [coloredY{x, y}, reconstructedY{x, y}, previousMV] = obj.getReconstructedBlock(splitS, mv, residual, x, y, previousMV, mvL, obj.FMEEnable, currQP);
                end
            end
            coloredY = uint8(cell2mat(coloredY));
            reconstructedY = uint8(cell2mat(reconstructedY));
        end

        function [coloredY, reconstructedY] = reconstructedFrame(obj)
            coloredY = {};
            reconstructedY = {};
            startIdx = 1;
            splitBlocks = obj.getSplitStrBlocks();
            xBlocks = obj.width / obj.blockSize;
            if obj.nRefFrames > 1
                mvL = 3;
            else
                mvL = 2;
            end
            for x = 1 : obj.height / obj.blockSize
                previousMV = zeros(1, mvL);
                for y = 1 : obj.width / obj.blockSize
                    splitS = cell2mat(splitBlocks((x - 1) * xBlocks + y));
                    mv = entropy(obj.entropyedMV{x, y}, obj.blockSize).decode(0);
                    residual = entropy(obj.entropyedResidual{x, y}, obj.blockSize).decode(0);
                    [coloredY{x, y}, reconstructedY{x, y}, previousMV] = obj.getReconstructedBlock(splitS, mv, residual, x, y, previousMV, mvL, obj.FMEEnable, obj.QP);
                end
            end
            coloredY = uint8(cell2mat(coloredY));
            reconstructedY = uint8(cell2mat(reconstructedY));
        end

        function [coloredY, reconstructed, previousMV] = getReconstructedBlock(obj, splitS, mv, residual, x, y, previousMV, mvL, FMEEnable, QP)
            mvIdx = 1;
            residualIdx = 1;
            frameX = (x - 1) * obj.blockSize;
            frameY = (y - 1) * obj.blockSize;
            m = 1;
            n = 1;
            reconstructed = zeros(obj.blockSize, obj.blockSize);
            coloredY = zeros(obj.blockSize, obj.blockSize, 3);
            directions = [];
            direction = 0;
            previousI = -1;
            for s = 1 : length(splitS)
                currI = splitS(s);
                currQP = QP - log2(double(obj.blockSize) / double(currI));
                if currQP < 0
                    currQP = 0;
                end

                currMV = mv(mvIdx : mvIdx + mvL - 1);
                if obj.isDifferential
                    currMV = currMV + previousMV;
                end
                mvIdx = mvIdx + mvL;
                en = entropy(residual, currI);
                [currResidual, residualIdx] = en.decodeRLEBlock(residualIdx);
                currResidual = en.reorderToBlock(currResidual);
                currResidual = rescaledFrame(currResidual, currI, currQP).getRescaledBlock(currResidual, currQP);
                currResidual = round(idct2(currResidual));
                [coloredB, reconstructedB] = obj.getColoredBlock(currMV, currResidual, currI, frameX + m, frameY + n, FMEEnable);
                reconstructed(m : m + currI - 1, n : n + currI - 1) = reconstructedB;
                coloredY(m : m + currI - 1, n : n + currI - 1, :) = coloredB;

                previousMV = currMV;
                [m, n, direction, directions] = obj.getNewCoord(currI, previousI, directions, direction, m, n);
                previousI = currI;

            end
        end

        function [m, n, direction, directions] = getNewCoord(obj, currI, previousI, directions, direction, m, n)
            % get new (m, n) from current idx.
            if previousI == -1 && currI < obj.blockSize
                directions = [directions, 1];
            end
            if previousI ~= -1 && currI < previousI
                % subblock, save current block direction
                directions = [directions, direction + 1];
                direction = 1;
            elseif previousI ~= -1 && currI > previousI
                % next block
                direction = directions(length(directions));
                directions = directions(1 : length(directions) - 1);
            elseif direction == 3
                % next block, change parent direction to next
                direction = 0;
            else
                direction = direction + 1;
            end

            if direction == 1 || direction == 3
                n = n + currI;
            elseif direction == 2
                m = m + currI;
                n = n - currI;
            else
                if length(directions) < 1
                    direction = 0;
                else
                    direction = directions(length(directions));
                    directions = directions(1 : length(directions) - 1);
                end

                if direction == 3 && currI == previousI
                    m = m - currI;
                    n = n + currI;
                elseif direction == 2 && currI == previousI
                    m = m + currI;
                    n = n - currI * 3;
                elseif direction == 1 || direction == 3
                    m = m - currI;
                    n = n + currI;
                else
                    n = n + currI;
                    m = m - currI;
                end
                directions = [directions, direction + 1];
                direction = 0;
            end
        end
        function [coloredY, reconstructedY] = getColoredBlock(obj, mv, residual, currI, x, y, FMEEnable)
            if length(mv) < 3
                mvF = 0;
            else
                mvF = mv(3);
            end
            predictedFrame = obj.referenceFrames{length(obj.referenceFrames) - mvF}.frameData;
            if FMEEnable
                if (rem(mv(1), 2) == 0 && rem(mv(2), 2) == 0)
                    predictedX = x + mv(1)/2;
                    predictedY = y - mv(2)/2;
                    predicted = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
                elseif (rem(mv(1), 2) ~= 0 && rem(mv(2), 2) == 0)
                    predictedX = x + (mv(1) + 1)/2;
                    predictedY = y - mv(2)/2;
                    predictedA = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
                    predictedX = x + (mv(1) - 1)/2;
                    predictedY = y - mv(2)/2;
                    predictedB = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
                    predicted = obj.newdata(predictedA, predictedB);
                elseif (rem(mv(1), 2) == 0 && rem(mv(2), 2) ~= 0)
                    predictedX = x + mv(1)/2;
                    predictedY = y - (mv(2)+1)/2;
                    predictedA = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
                    predictedX = x + mv(1)/2;
                    predictedY = y - (mv(2)-1)/2;
                    predictedB = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
                    predicted = obj.newdata(predictedA, predictedB);
                else
                    predictedX = x + (mv(1) + 1)/2;
                    predictedY = y - (mv(2) + 1)/2;
                    predictedA = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
                    predictedX = x + (mv(1) + 1)/2;
                    predictedY = y - (mv(2) - 1)/2;
                    predictedB = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
                    predictedX = x + (mv(1) - 1)/2;
                    predictedY = y - (mv(2) + 1)/2;
                    predictedC = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
                    predictedX = x + (mv(1) - 1)/2;
                    predictedY = y - (mv(2) - 1)/2;
                    predictedD = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
    
                    predictedAB = obj.newdata(predictedA, predictedB);
                    predictedABC = obj.newdata(predictedAB, predictedC);
                    predicted = obj.newdata(predictedABC, predictedD);
                end
            else
                predictedX = x + mv(1);
                predictedY = y - mv(2);
                predicted = predictedFrame(predictedX : predictedX + currI - 1, predictedY : predictedY + currI - 1);
            end
            reconstructedY = uint8(double(predicted) + double(residual));
            coloredY = repmat(reconstructedY, 1, 1, 3);
            % coloredY(1, :, :) = 0;
            % coloredY(:, 1, :) = 0;
            % coloredY(currI, :, :) = 0;
            % coloredY(:, currI, :) = 0;
            % if obj.nRefFrames > 1
            %     if mvF ~= 0
            %         coloredY(:, :, mvF) = 255;
            %     end
            % end
        end

        function splitStrs = getSplitStrBlocks(obj)
            splitStrs = {};
            idx = 1;
            while idx <= length(obj.splitStr)
                [idx, splitS] = obj.getNextSplitString(idx, obj.blockSize, []);
                splitStrs{length(splitStrs) + 1} = splitS;
            end
        end

        function [idx, splitS] = getNextSplitString(obj, idx, currI, splitS)
            if obj.splitStr(idx) == '0'
                splitS = [splitS, currI];
                idx = idx + 1;
            else
                idx = idx + 1;
                currI = currI / 2;
                [idx, splitS] = obj.getNextSplitString(idx, currI, splitS);
                [idx, splitS] = obj.getNextSplitString(idx, currI, splitS);
                [idx, splitS] = obj.getNextSplitString(idx, currI, splitS);
                [idx, splitS] = obj.getNextSplitString(idx, currI, splitS);
            end
        end
        
        function newdata = newdata(obj, dataA, dataB)
            sizeofblock = size(dataA);
            newdata = zeros(sizeofblock(1), sizeofblock(2));
            for x = 1:sizeofblock(1)
                for y = 1:sizeofblock(2)
                    newdata(x,y) = round((uint16(dataA(x,y)) + uint16(dataB(x,y)))/2);
                end
            end
        end
    end

end