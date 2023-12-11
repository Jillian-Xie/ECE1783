classdef fractionalMotionEstimation
    %VIDEO Summary of this class goes here
    properties
        currFrame;
        refFrames;
        nRefFrames;
    end

    methods
        function obj = fractionalMotionEstimation(currData, refFrames, nRefFrames)
            obj.currFrame = currData;
            obj.refFrames = refFrames;
            obj.nRefFrames = nRefFrames;
        end

        function [mat, motionVectors] = getBestPredictedBlocksPerRow(obj, x, r, isMAE, FastME, rowCount)
            % find best predict block for all blocks
            motionVectors = {};
            mat = {};
            blocks = obj.currFrame.blocks;
            s = size(blocks);
            previousMV = zeros(1, 2);
            for currX = x : x + rowCount - 1
                for y = 1 : s(2)
                    [m, mv] = obj.getBestBlockAcrossFrames(currX, y, r, isMAE, FastME, previousMV);
                    motionVectors{currX - x + 1, y} = mv;
                    mat{currX - x + 1, y} = m; 
                    if length(mv) == 3
                        previousMV = mv(1 : 2);
                    end
                end
            end
        end

        function [mat, motionVectors] = getBestPredictedBlocks(obj, r, isMAE, FastME)
            % find best predict block for all blocks
            motionVectors = {};
            mat = {};
            blocks = obj.currFrame.blocks;
            s = size(blocks);
            % start with (0,0)
            for x = 1 : s(1)
                previousMV = zeros(1, 2);
                for y = 1 : s(2)
                    [m, mv] = obj.getBestBlockAcrossFrames(x, y, r, isMAE, FastME, previousMV);
                    motionVectors{x, y} = mv;
                    mat{x, y} = m; 
                    if length(mv) == 3
                        previousMV = mv(1 : 2);
                    end
                end
            end
        end

        function [m, motionVector] = getBestBlockAcrossFrames(obj, x, y, r, isMAE, FastME, previousMV)
            if FastME == 1
                smallestMAE = -1;
                resultMV = previousMV;
                blockSize = size(obj.currFrame.blocks{1,1}, 1);
                for f = 1 : length(obj.refFrames)
                    [mae, mv] = obj.getNNBestMatch(obj.refFrames{f}, x, y, r, isMAE, previousMV, blockSize);
                    if smallestMAE == -1 || mae < smallestMAE
                        smallestMAE = mae;
                        resultMV = mv;
                        if obj.nRefFrames > 1
                            resultMV(3) = length(obj.refFrames) - f;
                        end
                    end
                end
                m = smallestMAE;
                motionVector = double(resultMV);
            else 
                matrix = zeros(1 + 4 * r, 1 + 4 * r, length(obj.refFrames));
                for i = 1 : length(obj.refFrames)
                    matrix(:, :, i) = obj.getMatrix(x, y, r, obj.refFrames{i}, isMAE);
                end
                [m, motionVector] = obj.getBlockWithSmallestDiff(matrix, r);
            end
        end

        function [newMV, diff] = getReferenceDiffByMV(obj, refFrame, x, y, r, mv, direction, isMAE, isOrigin, blockSize)
            newMV = mv + direction;
            if isOrigin == 0 && all(mv == newMV)
                diff = nan;
            else
                % currBlock = cell2mat(obj.currFrame.blocks(x, y));
                currBlock = obj.currFrame.frameData(1 + (x - 1) * blockSize : x * blockSize, 1 + (y - 1) * blockSize : y * blockSize);
                blockSize = size(currBlock);

                if newMV(1) > 2 * r || newMV(1) < -2 * r || newMV(2) > 2 * r || newMV(2) < -2 * r 
                    diff = nan;
                else
                    if mod(newMV(1), 2) == 0 && mod(newMV(2), 2) == 0
                        % original data
                        predictedX = 1 + (x - 1) * blockSize(1) + floor(newMV(1) / 2);
                        predictedY = 1 + (y - 1) * blockSize(1) - floor(newMV(2) / 2);
                        if predictedX <= 0 || predictedX + blockSize(1) - 1 > obj.currFrame.height || predictedY <= 0 || predictedY + blockSize(1) - 1 > obj.currFrame.width
                           diff = nan;
                        else
                            previous = refFrame(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                            diff = obj.calculateDiff(previous, currBlock, isMAE);
                        end
                    elseif mod(newMV(1), 2) == 0 && mod(newMV(2), 2) ~= 0
                        % block should be the average of left and right blocks
                        predictedX1 = 1 + (x - 1) * blockSize(1) + floor(newMV(1) / 2);
                        predictedY1 = 1 + (y - 1) * blockSize(1) - floor(newMV(2) / 2);
                        predictedX2 = 1 + (x - 1) * blockSize(1) + floor(newMV(1) / 2);
                        predictedY2 = 1 + (y - 1) * blockSize(1) - ceil(newMV(2) / 2);
                        if predictedX1 <= 0 || predictedX1 + blockSize(1) - 1 > obj.currFrame.height || predictedY1 <= 0 || predictedY1 + blockSize(1) - 1 > obj.currFrame.width
                           diff = nan;
                        elseif predictedX2 <= 0 || predictedX2 + blockSize(1) - 1 > obj.currFrame.height || predictedY2 <= 0 || predictedY2 + blockSize(1) - 1 > obj.currFrame.width
                            diff = nan;
                        else
                            previous1 = refFrame(predictedX1 : predictedX1 + blockSize(1) - 1, predictedY1 : predictedY1 + blockSize(1) - 1);
                            previous2 = refFrame(predictedX2 : predictedX2 + blockSize(1) - 1, predictedY2 : predictedY2 + blockSize(1) - 1);
                            diff = obj.calculateDiff(obj.newdata(previous1, previous2), currBlock, isMAE);
                        end
                    elseif mod(newMV(1), 2) ~= 0 && mod(newMV(2), 2) == 0
                        % block should be average of top and bottom blocks
                        predictedX1 = 1 + (x - 1) * blockSize(1) + floor(newMV(1) / 2);
                        predictedY1 = 1 + (y - 1) * blockSize(1) - floor(newMV(2) / 2);
                        predictedX2 = 1 + (x - 1) * blockSize(1) + ceil(newMV(1) / 2);
                        predictedY2 = 1 + (y - 1) * blockSize(1) - floor(newMV(2) / 2);
                        if predictedX1 <= 0 || predictedX1 + blockSize(1) - 1 > obj.currFrame.height || predictedY1 <= 0 || predictedY1 + blockSize(1) - 1 > obj.currFrame.width
                           diff = nan;
                        elseif predictedX2 <= 0 || predictedX2 + blockSize(1) - 1 > obj.currFrame.height || predictedY2 <= 0 || predictedY2 + blockSize(1) - 1 > obj.currFrame.width
                            diff = nan;
                        else
                            previous1 = refFrame(predictedX1 : predictedX1 + blockSize(1) - 1, predictedY1 : predictedY1 + blockSize(1) - 1);
                            previous2 = refFrame(predictedX2 : predictedX2 + blockSize(1) - 1, predictedY2 : predictedY2 + blockSize(1) - 1);
                            diff = obj.calculateDiff(obj.newdata(previous1, previous2), currBlock, isMAE);
                        end
                    else
                        % average of left,right,top,bottom blocks
                        predictedX1 = 1 + (x - 1) * blockSize(1) + floor(newMV(1) / 2);
                        predictedY1 = 1 + (y - 1) * blockSize(1) - floor(newMV(2) / 2);

                        predictedX2 = 1 + (x - 1) * blockSize(1) + floor(newMV(1) / 2);
                        predictedY2 = 1 + (y - 1) * blockSize(1) - ceil(newMV(2) / 2);

                        predictedX3 = 1 + (x - 1) * blockSize(1) + ceil(newMV(1) / 2);
                        predictedY3 = 1 + (y - 1) * blockSize(1) - floor(newMV(2) / 2);

                        predictedX4 = 1 + (x - 1) * blockSize(1) + ceil(newMV(1) / 2);
                        predictedY4 = 1 + (y - 1) * blockSize(1) - ceil(newMV(2) / 2);
                        if predictedX1 <= 0 || predictedX1 + blockSize(1) - 1 > obj.currFrame.height || predictedY1 <= 0 || predictedY1 + blockSize(1) - 1 > obj.currFrame.width
                           diff = nan;
                        elseif predictedX2 <= 0 || predictedX2 + blockSize(1) - 1 > obj.currFrame.height || predictedY2 <= 0 || predictedY2 + blockSize(1) - 1 > obj.currFrame.width
                            diff = nan;
                        elseif predictedX3 <= 0 || predictedX3 + blockSize(1) - 1 > obj.currFrame.height || predictedY3 <= 0 || predictedY3 + blockSize(1) - 1 > obj.currFrame.width
                            diff = nan;
                        elseif predictedX4 <= 0 || predictedX4 + blockSize(1) - 1 > obj.currFrame.height || predictedY4 <= 0 || predictedY4 + blockSize(1) - 1 > obj.currFrame.width
                            diff = nan;
                        else
                            previous1 = refFrame(predictedX1 : predictedX1 + blockSize(1) - 1, predictedY1 : predictedY1 + blockSize(1) - 1);
                            previous2 = refFrame(predictedX2 : predictedX2 + blockSize(1) - 1, predictedY2 : predictedY2 + blockSize(1) - 1);
                            previous3 = refFrame(predictedX3 : predictedX3 + blockSize(1) - 1, predictedY3 : predictedY3 + blockSize(1) - 1);
                            previous4 = refFrame(predictedX4 : predictedX4 + blockSize(1) - 1, predictedY4 : predictedY4 + blockSize(1) - 1);
                            diff = obj.calculateDiff(obj.newdata(obj.newdata(previous1, previous2), obj.newdata(previous3, previous4)), currBlock, isMAE);
                        end
                    end
                end
            end
        end

        function [mae, mv] = getNNBestMatchStep(obj, refFrameData, x, y, r, isMAE, directions, minMAE, prevMV, step, blockSize)
            mae = minMAE;
            mv = prevMV;
            if step <= 3
                maes = [];
                mvs = [];
                for d = 1 : size(directions, 1)
                    direction = directions(d, :);
                    [currMv, currMae] = obj.getReferenceDiffByMV(refFrameData, x, y, r, prevMV, direction, isMAE, 0, blockSize);
                    maes = [maes, currMae];
                    mvs = [mvs; currMv];
                end 
                curMinMAE =  min(maes);
                if ~isnan(curMinMAE)
                    currMAEIdx = find(maes == curMinMAE);
                    if curMinMAE > minMAE
                        mae = minMAE;
                        mv = prevMV;
                    else
                        if length(currMAEIdx) == 1
                            if mod(currMAEIdx, 2) == 0
                                directions(currMAEIdx - 1, :) = [0, 0];
                            else
                                directions(currMAEIdx + 1, :) = [0, 0];
                            end
                            [mae, mv] = obj.getNNBestMatchStep(refFrameData, x, y, r, isMAE, directions, curMinMAE, mvs(currMAEIdx, :), step + 1, blockSize);
                        else
                            for idx = 1 : length(currMAEIdx)
                                tempDirections = directions;
                                if mod(currMAEIdx, 2) == 0
                                    tempDirections(currMAEIdx(idx) - 1, :) = [0, 0];
                                else
                                    tempDirections(currMAEIdx(idx) + 1, :) = [0, 0];
                                end
                                [mae, mv] = obj.getNNBestMatchStep(refFrameData, x, y, r, isMAE, tempDirections, curMinMAE, mvs(currMAEIdx(idx), :), step + 1, blockSize);
                            end
                        end
                    end
                end
            end
        end
        function [mae, mv] = getNNBestMatch(obj, refFrame, x, y, r, isMAE, previousMV, blockSize)
            refFrameData = refFrame.frameData;
            [mv, mae] = obj.getReferenceDiffByMV(refFrameData, x, y, r, previousMV, [0, 0], isMAE, 1, blockSize);
            directions = [[1, 0]; [-1, 0]; [0, 1]; [0, -1]];
            [mae, mv] = obj.getNNBestMatchStep(refFrameData, x, y, r, isMAE, directions, mae, mv, 1, blockSize);

            if isnan(mae)
                matrix = zeros(1 + 4 * r, 1 + 4 * r);
                matrix(:, :) = obj.getMatrix(x, y, r, refFrame, isMAE);
                [mae, mv] = obj.getFrameBlockWithSmallestDiff(matrix, r);
            end
        end

        function [currMin, motionVector] = getFrameBlockWithSmallestDiff(obj, matrix, r)
            s = size(matrix);
            x = 1;
            y = 1;
            currMin = matrix(x , y);
            l1norm = abs(-r + x - 1) + abs(r - y + 1);
            for m = 1 : s(1)
                for n = 1 : s(2)
                    temp = matrix(m, n);
                    if (temp < currMin)
                        x = m;
                        y = n;
                        currMin = temp;
                    elseif (temp == currMin)
                        % choose mv as smallest L1 norm
                        currL1norm = abs(-r + m - 1) + abs(r - n + 1);
                        if currL1norm < l1norm
                            l1norm = currL1norm;
                            x = m;
                            y = n;
                        elseif currL1norm == l1norm
                            if r - n + 1 < y
                                % choose with smallest y
                                x = m;
                                y = n;
                            elseif r - n + 1 == y && -r + x - 1 < x
                                % choose with smallest x
                                x = m;
                                y = n;
                            end
                        end
                    end
                end
            end
            motionVector = [-2*r + x - 1, 2*r - y + 1];
        end


        function [currMin, motionVector] = getBlockWithSmallestDiff(obj, matrix, r)
            % find best predict block for a block
            s = size(matrix);
            refF = 1;
            x = 1;
            y = 1;
            currMin = matrix(x , y, refF);
            l1norm = abs(-2*r + x - 1) + abs(2*r - y + 1);
            for f = 1 : length(obj.refFrames)
                for m = 1 : s(1)
                    for n = 1 : s(2)
                        if length(obj.refFrames) > 1, temp = matrix(m, n, f); else, temp = matrix(m, n); end
                        if (temp < currMin)
                            x = m;
                            y = n;
                            refF = f;
                            currMin = temp;
                        elseif (temp == currMin)
                            % choose mv as smallest L1 norm
                            currL1norm = abs(-2*r + m - 1) + abs(2*r - n + 1);
                            if currL1norm < l1norm
                                l1norm = currL1norm;
                                x = m;
                                y = n;
                            elseif currL1norm == l1norm
                                if 2*r - n + 1 < y
                                    % choose with smallest y
                                    x = m;
                                    y = n;
                                    refF = f;
                                elseif 2*r - n + 1 == y && -2*r + x - 1 < x
                                    % choose with smallest x
                                    x = m;
                                    y = n;
                                    refF = f;
                                elseif 2*r - n + 1 == y && -2*r + x - 1 == x && f > refF
                                    % choose with largest f
                                    x = m;
                                    y = n;
                                    refF = f;
                                end
                            end
                        end
                    end
                end
            end
            if obj.nRefFrames > 1

                motionVector = [-2*r + x - 1, 2*r - y + 1, length(obj.refFrames) - refF];
            else
                motionVector = [-2*r + x - 1, 2*r - y + 1];
            end
        end

        function matrix = getMatrix(obj, x, y, r, refFrame, isMAE)
            % find matrix given block coor (x, y) with search range r pixels
            currBlock = cell2mat(obj.currFrame.blocks(x, y));
            blockSize = size(currBlock);
            refFrame = refFrame.frameData;

            % get (x, y) as frame coord
            locationX = (x - 1) * blockSize(1) + 1;
            locationY = (y - 1) * blockSize(1) + 1;

            % initialize empty matrix
            matrix = zeros(1 + 4 * r, 1 + 4 * r);
            previousBlockData = {};
            for m = locationX - r : locationX + r
                for n = locationY - r : locationY + r
                    matrixX = m - (locationX - r) + 1;
                    matrixY = n - (locationY - r) + 1;
                    if m <= 0 || m + blockSize(1) - 1 > obj.currFrame.height || n <= 0 || n + blockSize(1) - 1 > obj.currFrame.width
                        % find corrresponding block data in previous frame
                        % skip boundary blocks
                        matrix(2*matrixX-1, 2*matrixY-1) = intmax();
                    else
                        previous = refFrame(m : m + blockSize(1) - 1, n : n + blockSize(1) - 1);
                        previousBlockData{2*matrixX-1, 2*matrixY-1} = previous;
                        matrix(2*matrixX-1, 2*matrixY-1) = obj.calculateDiff(previous, currBlock, isMAE);
                    end
                end
            end

            sizeofpreviousBlockData = size(previousBlockData);
            for a = 1 : 4*r+1
                for b = 1: 4*r+1
                    if a > sizeofpreviousBlockData(1) || b > sizeofpreviousBlockData(2)
                        matrix(a, b) = intmax();
                    elseif rem(a,2) == 0 && rem(b,2) ~=0
                        if (isempty(previousBlockData{a-1,b}) || isempty(previousBlockData{a+1,b}) )
                            matrix(a,b) = intmax();
                            continue
                        else
                            previousA = previousBlockData{a-1, b};
                            previousB = previousBlockData{a+1, b};
                            matrix(a, b) = obj.calculateDiff(obj.newdata(previousA, previousB), currBlock, isMAE);
                        end
                    elseif rem(a,2) ~= 0 && rem(b,2) == 0
                        if (isempty(previousBlockData{a, b-1}) || isempty(previousBlockData{a, b+1}))
                            matrix(a,b) = intmax();
                            continue
                        else
                            previousA = previousBlockData{a, b-1};
                            previousB = previousBlockData{a, b+1};
                            matrix(a,b) = obj.calculateDiff(obj.newdata(previousA, previousB), currBlock, isMAE);
                        end
                    elseif rem(a,2) == 0 && rem(b,2) == 0
                        if (isempty(previousBlockData{a-1, b-1}) || isempty(previousBlockData{a+1, b-1}) || isempty(previousBlockData{a-1, b+1}) || isempty(previousBlockData{a+1, b+1}))
                            matrix(a,b) = intmax();
                            continue
                        else
                            previousBlock = obj.newdata(previousBlockData{a-1, b-1}, previousBlockData{a+1, b-1});
                            previousBlock = obj.newdata(previousBlock, previousBlockData{a-1, b+1});
                            previousBlock = obj.newdata(previousBlock, previousBlockData{a+1, b+1});
                            matrix(a,b) = obj.calculateDiff(previousBlock, currBlock, isMAE);
                        end
                    else
                        continue
                    end
                end
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

        function blockdiff = calculateDiff(obj, block1, block2, isMAE)
            sizeofblock = size(block1);
            height = sizeofblock(1,1);
            width = sizeofblock(1,2);
            blockdiff = sum(abs(double(block1)- double(block2)), "all");
            if isMAE
                blockdiff = double(blockdiff) / (height*width);
            end
        end

        function approximatedBlocks = getApproximatedResidualBlocksPerRow(obj, motionVectors, n, x, rowCount)
            s = size(motionVectors);
            approximatedBlocks = {};
            for currX = x : x + rowCount - 1
                for y = 1 : s(2)
                    residual = obj.getResidualBlock(currX, y, motionVectors(currX - x + 1, y));
                    approximatedBlocks{currX - x + 1, y} = obj.getApproximatedResidualBlock(residual, n);
                end
            end
        end

        function approximatedBlocks = getApproximatedResidualBlocks(obj, motionVectors, n)
            s = size(motionVectors);
            approximatedBlocks = {};
            for x = 1 : s(1)
                for y = 1 : s(2)
                    residual = obj.getResidualBlock(x, y, motionVectors(x, y));
                    approximatedBlocks{x, y} = obj.getApproximatedResidualBlock(residual, n);
                end
            end
        end

        function residualBlock = getResidualBlock(obj, x, y, motionVector)
            curr = cell2mat(obj.currFrame.blocks(x, y));
            blockSize = size(curr);
            if iscell(motionVector)
                mv = cell2mat(motionVector);
            else
                mv = motionVector;
            end
            if length(mv) == 3
                refFrame = obj.refFrames{length(obj.refFrames) - mv(3)};
            else
                refFrame = obj.refFrames{1};
            end
            if (rem(mv(1), 2) == 0 && rem(mv(2), 2) == 0)
                predictedX = 1 + (x - 1) * blockSize(1) + mv(1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - mv(2)/2;
                predicted = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
            elseif (rem(mv(1), 2) ~= 0 && rem(mv(2), 2) == 0)
                predictedX = 1 + (x - 1) * blockSize(1) + (mv(1) + 1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - mv(2)/2;
                predictedA = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                predictedX = 1 + (x - 1) * blockSize(1) + (mv(1) - 1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - mv(2)/2;
                predictedB = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                predicted = obj.newdata(predictedA, predictedB);
            elseif (rem(mv(1), 2) == 0 && rem(mv(2), 2) ~= 0)
                predictedX = 1 + (x - 1) * blockSize(1) + mv(1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - (mv(2)+1)/2;
                predictedA = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                predictedX = 1 + (x - 1) * blockSize(1) + mv(1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - (mv(2)-1)/2;
                predictedB = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                predicted = obj.newdata(predictedA, predictedB);
            else
                predictedX = 1 + (x - 1) * blockSize(1) + (mv(1) + 1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - (mv(2) + 1)/2;
                predictedA = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                predictedX = 1 + (x - 1) * blockSize(1) + (mv(1) + 1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - (mv(2) - 1)/2;
                predictedB = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                predictedX = 1 + (x - 1) * blockSize(1) + (mv(1) - 1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - (mv(2) + 1)/2;
                predictedC = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                predictedX = 1 + (x - 1) * blockSize(1) + (mv(1) - 1)/2;
                predictedY = 1 + (y - 1) * blockSize(1) - (mv(2) - 1)/2;
                predictedD = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);

                predictedAB = obj.newdata(predictedA, predictedB);
                predictedABC = obj.newdata(predictedAB, predictedC);
                predicted = obj.newdata(predictedABC, predictedD);
            end
            residualBlock = double(curr) - double(predicted);
        end

        function approximated = getApproximatedResidualBlock(obj, residual, n)
            multiple = pow2(n);
            sizeofblock = size(residual);
            approximated = zeros(sizeofblock(1,1), sizeofblock(1,2));
            for x = 1:sizeofblock(1,1)
                for y = 1:sizeofblock(1,2)
                    approximated(x, y) = obj.roundN(residual(x, y), multiple);
                end
            end
        end

        function num = roundN(obj, num, multiple)
            remain = mod(num, multiple);
            if remain ~= 0
                c = ceil(num / multiple);
                f = floor(num / multiple);
                if abs(c - num) > abs(num - f)
                    num = f * multiple;
                else
                    num = c * multiple;
                end
            end
        end

        function [colored, reconstructedY] = getReconstructedFrame(obj, motionVectors, approximatedBlocks, nRefFrames, VBSEnable, FMEEnable)
            motionVectors = cell2mat(motionVectors);
            approximatedBlocks = cell2mat(approximatedBlocks);
            frame = reconstructedFrame(obj.refFrames, motionVectors, approximatedBlocks, nRefFrames, VBSEnable, FMEEnable);
            [colored, reconstructedY] = frame.reconstruct();
        end

        function dctTransformed = getDCTBlocks(obj, residuals)
            % use dct2 from image processing toolbox and round
            s = size(residuals);
            dctTransformed = {};
            for x = 1 : s(1)
                for y = 1 : s(2)
                    dctTransformed{x, y} = round(dct2(cell2mat(residuals(x, y))));
                end
            end
        end

        function QTCs = getQuatizedBlocks(obj, TC, QP)
            % build QTC according to QP
            s = size(TC);
            QTCs = {};
            for x = 1 : s(1)
                for y = 1 : s(2)
                    QTCs{x, y} = obj.getQuatizedBlock(cell2mat(TC(x, y)), QP);
                end
            end
        end

        function QTC = getQuatizedBlock(obj, transformed, QP)
            blockSize = size(transformed, 1);
            QTC = ones(blockSize, blockSize);
            for x = 1 : blockSize
                for y = 1 : blockSize
                    if obj.isValidQP(QP, blockSize)
                        QTC(x, y) = round(transformed(x, y) / obj.getQ(QP, x, y, blockSize));
                    end
                end
            end
        end

        function Q = getQ(obj, QP, x, y, blockSize)
            if x + y < blockSize - 1
                Q = pow2(QP);
            elseif x + y == blockSize - 1
                Q = pow2(QP + 1);
            else
                Q = pow2(QP + 2);
            end
        end

        function isValid = isValidQP(obj, QP, blockSize)
            if QP < 0
                isValid = false;
            elseif QP > log2(double(blockSize)) + 7
                isValid = false;
            else
                isValid = true;
            end
        end
    end
end