classdef RCMotionEstimator < fractionalMotionEstimation
    properties
        blockSize;
        subBlocks;
        rc; % rateController
    end

    methods
        function obj = RCMotionEstimator(curr, refs, nRefFrames, blockSize)
            obj = obj@fractionalMotionEstimation(curr, refs, nRefFrames);
            obj.blockSize = blockSize;
        end

        function obj = addRateController(obj, rc)
            obj.rc = rc;
        end

        function splitStrs = getSplitStrBlocks(obj, splitStr)
            splitStrs = {};
            idx = 1;
            while idx <= length(splitStr)
                [idx, splitS] = obj.getNextSplitString(splitStr, idx, obj.blockSize, []);
                splitStrs{length(splitStrs) + 1} = splitS;
            end
        end

        function [idx, splitS] = getNextSplitString(obj, splitStr, idx, currI, splitS)
            if splitStr(idx) == '0'
                splitS = [splitS, currI];
                idx = idx + 1;
            else
                idx = idx + 1;
                currI = currI / 2;
                [idx, splitS] = obj.getNextSplitString(splitStr, idx, currI, splitS);
                [idx, splitS] = obj.getNextSplitString(splitStr, idx, currI, splitS);
                [idx, splitS] = obj.getNextSplitString(splitStr, idx, currI, splitS);
                [idx, splitS] = obj.getNextSplitString(splitStr, idx, currI, splitS);
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

        function [QPs, motionVectors, approximatedBlocks] = getVBPerRowWithMV(obj, r, n, previousQPs, bitPerRow, frameType, prevMVs, splitStr)
            n_param = n;
            % based on know splitStr and motion Vectors
            % split block based on known splitStr
            % restrict search area as MV (x +- 2, y +- 2)
            obj.rc = obj.rc.updateRemainingBit(strlength(splitStr));

            totalBitCount = sum(bitPerRow);
            QPs = [];
            motionVectors = {};
            approximatedBlocks = {};

            if obj.nRefFrames > 1
                mvL = 3;
            else
                mvL = 2;
            end
            splitStrBlocks = obj.getSplitStrBlocks(splitStr);
            xBlocks = obj.currFrame.width / obj.blockSize;
            for x = 1 : obj.currFrame.height / obj.blockSize
                frameX = (x - 1) * obj.blockSize;
                prop = bitPerRow(x) / totalBitCount;
                QP = obj.rc.getEstimatedPropQP(frameType, prop);
                QPs = [QPs, QP];
                bitCount = 0;
                prevMV = zeros(1, mvL);
                prevOldMV = zeros(1, mvL);
                for y = 1 : xBlocks
                    frameY = (y - 1) * obj.blockSize;
                    currBlock = obj.currFrame.frameData(1 + frameX : x * obj.blockSize, 1 + frameY : y * obj.blockSize);

                    splitS = cell2mat(splitStrBlocks((x - 1) * xBlocks + y));
                    diffMV = entropy(prevMVs{x, y}, obj.blockSize).decode(0);

                    mvIdx = 1;
                    newDiffMVs = [];
                    newResiduals = [];
                    m = 1;
                    n = 1;
                    directions = [];
                    direction = 0;
                    previousI = -1;
                    for s = 1 : length(splitS)
                        currI = splitS(s);
                        currMV = diffMV(mvIdx : mvIdx + mvL - 1) + prevOldMV;
                        mvIdx = mvIdx + mvL;
                        currBlockData = currBlock(m : m + currI - 1, n : n + currI - 1);

                        % set search range as the 1/4 around current
                        [smallestDiff, newMV, newRes] = obj.getBestBlockWithNN(currBlockData, frameX + m, frameY + n, r, currI, currMV, n_param, QP), 2;
                        % [smallestDiff, newMV, newRes] = obj.getBestBlockRefMV(currBlockData, frameX + m, frameY + n, r, currI, currMV, n_param, QP);
                        newDiffMV = newMV - prevMV;


                        [m, n, direction, directions] = obj.getNewCoord(currI, previousI, directions, direction, m, n);
                        if length(newResiduals) == 0
                            newResiduals = newRes;
                        else
                            newResiduals = [newResiduals, newRes];
                        end
                        newDiffMVs = [newDiffMVs, newDiffMV];
                        prevMV = newMV;
                        prevOldMV = currMV;
                        previousI = currI;
                    end
                    newResiduals = strjoin(newResiduals, "");
                    if y == 1
                        newResiduals = entropy(QP - previousQPs(x), obj.blockSize).encode(0, 0) + newResiduals;
                    end
                    entropyedMV = entropy(newDiffMVs, obj.blockSize).encode(0, 0);
                    motionVectors{x, y} = entropyedMV;
                    approximatedBlocks{x, y} = newResiduals;
                    bitCount = bitCount + strlength(entropyedMV) + strlength(newResiduals);
                end
                % obj.rc = obj.rc.updateRemainingBit(bitCount);
                % totalBitCount = totalBitCount - bitPerRow(x);
            end
        end

        function [smallestDiff, mv, residual] = getBestBlockWithNN(obj, currBlock, x, y, r, currI, refMV, n, QP, step)
            % get NN Best Match with smaller r range
            oldR = r;
            r = floor(r / 2);
            step = 2;
            directions = [[1, 0]; [-1, 0]; [0, 1]; [0, -1]];
            smallestDiff = intmax();
            residual = [];
            blockX = 1 + (x - 1) / currI;
            blockY = 1 + (y - 1) / currI;

            for i = 1 : length(obj.refFrames)
                refFrame = obj.refFrames{i}.frameData;
                [tempMv, mae] = obj.getReferenceDiffByMV(refFrame, blockX, blockY, r, refMV, [0, 0], 0, 1, currI);
                [mae, newMv] = obj.getNNBestMatchStep(refFrame, blockX, blockY, r, 0, directions, mae, tempMv, step, currI);
                if ~isnan(mae)
                    [diff, res] = obj.getDiff(currBlock, refFrame, x, y, newMv(1), newMv(2), currI);
                    if diff < smallestDiff
                        smallestDiff = diff;
                        mv = newMv;
                        residual = res;
                        if obj.nRefFrames > 1
                            mv = [mv, length(obj.refFrame) - i];
                        end
                    end
                end
            end

            if smallestDiff == intmax();
                [smallestDiff, mv, residual] = obj.getBestBlockRefMV(currBlock, x, y, oldR, currI, refMV, n, QP);
            else
                residual = obj.getResidualBlock(res, n, QP, currI);
            end
        end

        function [smallestDiff, mv, residual] = getBestBlockRefMV(obj, currBlock, x, y, r, currI, refMV, n, QP)
            smallestDiff = intmax();
            mv = [];
            residual = [];
            for i = 1 : length(obj.refFrames)
                refFrame = obj.refFrames{i}.frameData;

                % change to non-frac MV
                mvX = floor(refMV(1) / 2) * 2;
                mvY = floor(refMV(2) / 2) * 2;

                for newMVX = mvX - 4 : mvX + 4
                    for newMVY = mvY - 4 : mvY + 4
                        if newMVX < -2 * r || newMVX > 2 * r || newMVY < -2 * r || newMVY > 2*r
                            continue;
                        else
                            [diff, res] = obj.getDiff(currBlock, refFrame, x, y, newMVX, newMVY, currI);
                            if diff < smallestDiff
                                smallestDiff = diff;
                                mv = [newMVX, newMVY];
                                residual = res;
                                if obj.nRefFrames > 1
                                    mv = [mv, length(obj.refFrame) - i];
                                end
                            end
                        end
                    end
                end
            end
            if length(residual) < 1
                % still cannot find, do a full range search
                for newMVX = -2 * r : 2 * r
                    for newMVY = -2 * r : 2 * r
                        [diff, res] = obj.getDiff(currBlock, refFrame, x, y, newMVX, newMVY, currI);
                        if diff < smallestDiff
                            smallestDiff = diff;
                            mv = [newMVX, newMVY];
                            residual = res;
                            if obj.nRefFrames > 1
                                mv = [mv, length(obj.refFrame) - i];
                            end
                        end
                    end
                end
            end
            residual = obj.getResidualBlock(residual, n, QP, currI);
        end

        function residual = getResidualBlock(obj, residual, n, QP, currI)
            residual = obj.getApproximatedResidualBlock(residual, n);
            dctTransformed = round(dct2(residual));
            QTC = ones(currI, currI);
            for x = 1 : currI
                for y = 1 : currI
                    QTC(x, y) = round(dctTransformed(x, y) / obj.getQ(QP, x, y, currI));
                end
            end
            en = entropy(QTC, currI);
            reordered = en.reorderBlock(QTC);
            encodedQTC = en.RLE(reordered);
            residual = entropy(encodedQTC, currI).encode(0, 1);
        end

        function [diff, residual] = getDiff(obj, currBlock, refFrame, x, y, mvX, mvY, bs)
            if rem(mvX, 2) ~= 0 && rem(mvY, 2) == 0
                m1 = x + (mvX + 1) / 2;
                m2 = x + (mvX - 1) / 2;
                n = y - mvY / 2;
                if m2 <= 0 || m1 + bs - 1 > obj.currFrame.height || n <= 0 || n + bs - 1 > obj.currFrame.width
                    diff = intmax();
                    residual = [];
                else
                    refBlock1 = refFrame(m1 : m1 + bs - 1, n : n + bs - 1);
                    refBlock2 = refFrame(m2 : m2 + bs - 1, n : n + bs - 1);
                    refBlock = (uint16(refBlock1) + uint16(refBlock2)) / 2;
                    diff = sum(abs(double(currBlock)- double(refBlock)), "all");
                    residual = double(currBlock)- double(refBlock);
                end
            elseif rem(mvX, 2) == 0 && rem(mvY, 2) ~= 0
                m = x + mvX /2;
                n1 = y - (mvY + 1) /2;
                n2 = y - (mvY - 1) /2;
                if m <= 0 || m + bs - 1 > obj.currFrame.height || n1 <= 0 || n2 + bs - 1 > obj.currFrame.width
                    diff = intmax();
                    residual = [];
                else
                    refBlock1 = refFrame(m : m + bs - 1, n1 : n1 + bs - 1);
                    refBlock2 = refFrame(m : m + bs - 1, n2 : n2 + bs - 1);
                    refBlock = (uint16(refBlock1) + uint16(refBlock2)) / 2;
                    diff = sum(abs(double(currBlock)- double(refBlock)), "all");
                    residual = double(currBlock)- double(refBlock);
                end
            elseif rem(mvX, 2) ~= 0 && rem(mvY, 2) ~= 0
                m1 = x + (mvX - 1) / 2;
                m2 = x + (mvX + 1) / 2;
                n1 = y - (mvY - 1) / 2;
                n2 = y - (mvY + 1) / 2;
                if m1 <= 0 || m2 + bs - 1 > obj.currFrame.height || n2 <= 0 || n1 + bs - 1 > obj.currFrame.width
                    diff = intmax();
                    residual = [];
                else

                    refBlock1 = refFrame(m1 : m1 + bs - 1, n1 : n1 + bs - 1);
                    refBlock2 = refFrame(m2 : m2 + bs - 1, n1 : n1 + bs - 1);
                    refBlockA = (uint16(refBlock1) + uint16(refBlock2)) / 2;


                    refBlock1 = refFrame(m1 : m1 + bs - 1, n2 : n2 + bs - 1);
                    refBlock2 = refFrame(m2 : m2 + bs - 1, n2 : n2 + bs - 1);
                    refBlockB = (uint16(refBlock1) + uint16(refBlock2)) / 2;

                    refBlock = (uint16(refBlockA) + uint16(refBlockB)) / 2;
                    diff = sum(abs(double(currBlock)- double(refBlock)), "all");
                    residual = double(currBlock)- double(refBlock);
                end
            elseif rem(mvX, 2) == 0 && rem(mvY, 2) == 0
                m = x + mvX / 2;
                n = y - mvY / 2;
                if m <= 0 || m + bs - 1 > obj.currFrame.height || n <= 0 || n + bs - 1 > obj.currFrame.width
                    diff = intmax();
                    residual = [];
                else
                    refBlock = refFrame(m : m + bs - 1, n : n + bs - 1);
                    diff = sum(abs(double(currBlock)- double(refBlock)), "all");
                    residual = double(currBlock)- double(refBlock);
                end
            end
        end
    end
end