classdef frameMotionEstimator
    %VIDEO Summary of this class goes here
    properties
        currFrame;
        refFrames;
        nRefFrames;
    end

    methods
        function obj = frameMotionEstimator(currData, refFrames, nRefFrames)
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
                for f = 1 : length(obj.refFrames)
                    [mae, mv] = obj.getNNBestMatch(obj.refFrames{f}, x, y, r, isMAE, previousMV);
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
                matrix = zeros(1 + 2 * r, 1 + 2 * r, length(obj.refFrames));
                for i = 1 : length(obj.refFrames)
                    matrix(:, :, i) = obj.getMatrix(x, y, r, obj.refFrames{i}, isMAE);
                end
                [m, motionVector] = obj.getBlockWithSmallestDiff(matrix, r);
            end
        end

        function [newMV, diff] = getReferenceDiffByMV(obj, refFrame, x, y, r, mv, direction, isMAE, isOrigin)
            newMV = mv + direction;
            if isOrigin == 0 && all(mv == newMV)
                diff = nan;
            else
                currBlock = cell2mat(obj.currFrame.blocks(x, y));
                blockSize = size(currBlock);
                predictedX = 1 + (x - 1) * blockSize(1) + newMV(1);
                predictedY = 1 + (y - 1) * blockSize(1) - newMV(2);
                if newMV(1) > r || newMV(1) < -r || newMV(2) > r || newMV(2) < -r 
                    diff = nan;
                elseif predictedX <= 0 || predictedX + blockSize(1) - 1 > obj.currFrame.height || predictedY <= 0 || predictedY + blockSize(1) - 1 > obj.currFrame.width
                    diff = nan;
                else
                    previous = refFrame(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
                    diff = obj.calculateDiff(previous, currBlock, isMAE);
                end
            end
        end

        function [mae, mv] = getNNBestMatchStep(obj, refFrameData, x, y, r, isMAE, directions, minMAE, prevMV, step)
            mae = minMAE;
            mv = prevMV;
            if step <= 3
                maes = [];
                mvs = [];
                for d = 1 : size(directions, 1)
                    direction = directions(d, :);
                    [currMv, currMae] = obj.getReferenceDiffByMV(refFrameData, x, y, r, prevMV, direction, isMAE, 0);
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
                            [mae, mv] = obj.getNNBestMatchStep(refFrameData, x, y, r, isMAE, directions, curMinMAE, mvs(currMAEIdx, :), step + 1);
                        else
                            for idx = 1 : length(currMAEIdx)
                                tempDirections = directions;
                                if mod(currMAEIdx, 2) == 0
                                    tempDirections(currMAEIdx(idx) - 1, :) = [0, 0];
                                else
                                    tempDirections(currMAEIdx(idx) + 1, :) = [0, 0];
                                end
                                [mae, mv] = obj.getNNBestMatchStep(refFrameData, x, y, r, isMAE, tempDirections, curMinMAE, mvs(currMAEIdx(idx), :), step + 1);
                            end
                        end
                    end
                end
            end
        end
        function [mae, mv] = getNNBestMatch(obj, refFrame, x, y, r, isMAE, previousMV)
            refFrameData = refFrame.frameData;
            [mv, mae] = obj.getReferenceDiffByMV(refFrameData, x, y, r, previousMV, [0, 0], isMAE, 1);
            directions = [[1, 0]; [-1, 0]; [0, 1]; [0, -1]];
            [mae, mv] = obj.getNNBestMatchStep(refFrameData, x, y, r, isMAE, directions, mae, mv, 1);

            if isnan(mae)
                matrix = zeros(1 + 2 * r, 1 + 2 * r);
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
            motionVector = [-r + x - 1, r - y + 1];
        end

        function [currMin, motionVector] = getBlockWithSmallestDiff(obj, matrix, r)
            % find best predict block for a block
            s = size(matrix);
            refF = 1;
            x = 1;
            y = 1;
            currMin = matrix(x , y, refF);
            l1norm = abs(-r + x - 1) + abs(r - y + 1);
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
                                    refF = f;
                                elseif r - n + 1 == y && -r + x - 1 < x
                                    % choose with smallest x
                                    x = m;
                                    y = n;
                                    refF = f;
                                elseif r - n + 1 == y && -r + x - 1 == x && f > refF
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

                motionVector = [-r + x - 1, r - y + 1, length(obj.refFrames) - refF];
            else
                motionVector = [-r + x - 1, r - y + 1];
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
            matrix = zeros(1 + 2 * r, 1 + 2 * r);
            for m = locationX - r : locationX + r
                for n = locationY - r : locationY + r
                    matrixX = m - (locationX - r) + 1;
                    matrixY = n - (locationY - r) + 1;
                    if m <= 0 || m + blockSize(1) - 1 > obj.currFrame.height || n <= 0 || n + blockSize(1) - 1 > obj.currFrame.width
                        % find corrresponding block data in previous frame
                        % skip boundary blocks
                        matrix(matrixX, matrixY) = intmax();
                    else
                        previous = refFrame(m : m + blockSize(1) - 1, n : n + blockSize(1) - 1);
                        matrix(matrixX, matrixY) = obj.calculateDiff(previous, currBlock, isMAE);
                    end
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
            predictedX = 1 + (x - 1) * blockSize(1) + mv(1);
            predictedY = 1 + (y - 1) * blockSize(1) - mv(2);
            if length(mv) == 3
                refFrame = obj.refFrames{length(obj.refFrames) - mv(3)};
            else
                refFrame = obj.refFrames{1};
            end
            predicted = refFrame.frameData(predictedX : predictedX + blockSize(1) - 1, predictedY : predictedY + blockSize(1) - 1);
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
    end
end