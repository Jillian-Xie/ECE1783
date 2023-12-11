classdef VBSMotionEstimator < frameMotionEstimator
    properties
        blockSize;
        subBlockSize;
        QP;
        isDifferential;
        subBlocks;
        FMEEnable;
        rc; % rateController
        QP_delta;
        ROI; % region of interest
    end

    methods
        function obj = VBSMotionEstimator(curr, refs, nRefFrames, blockSize, j, QP, isDifferential, FMEEnable)
            obj = obj@frameMotionEstimator(curr, refs, nRefFrames);
            obj.blockSize = blockSize;
            obj.subBlockSize = pow2(j);
            obj.QP = QP;
            obj.isDifferential = isDifferential;
            obj.FMEEnable = FMEEnable;
        end

        function obj = addRateController(obj, rc)
            obj.rc = rc;
        end

        function obj = addQPDelta(obj, QP_delta)
            obj.QP_delta = QP_delta;
        end

        function [QPs, splitStr, motionVectors, approximatedBlocks] = getVBPerRowProp(obj, r, n, previousQPs, bitPerRow, frameType)
            % calculate sub blocks on per row base with various initial QP
            totalBitCount = sum(bitPerRow);
            splitStr = '';
            QPs = [];
            motionVectors = {};
            approximatedBlocks = {};
            if obj.nRefFrames > 1
                mvL = 3;
            else
                mvL = 2;
            end
            for x = 1 : obj.currFrame.height / obj.blockSize
                prop = bitPerRow(x) / totalBitCount;
                QP = obj.rc.getEstimatedPropQP(frameType, prop);
                QPs = [QPs, QP];
                bitCount = 0;
                prevMV = zeros(1, mvL);
                subBlocks = obj.createSubBlocksPerRow(x, r, n, 1, QP);
                for y = 1 : obj.currFrame.width / obj.blockSize
                    [s, mv, res] = obj.getSplittedData(subBlocks, obj.blockSize, 1, y);

                    mv = entropy(mv, obj.blockSize).decode(0);
                    temp = [];
                    for m = 1 : mvL : length(mv)
                        temp = [temp, mv(m : m + mvL - 1) - prevMV];
                        prevMV = mv(m : m + mvL - 1);
                    end
                    entropyedMV = entropy(temp, obj.blockSize).encode(0, 0);

                    if y == 1
                        res = entropy(QP - previousQPs(x), obj.blockSize).encode(0, 0) + res;
                    end

                    splitStr = [splitStr, s];
                    motionVectors{x, y} = entropyedMV;
                    approximatedBlocks{x, y} = res;
                    bitCount = bitCount + strlength(s) + strlength(entropyedMV) + strlength(res);
                end
                % obj.rc = obj.rc.updateRemainingBit(bitCount);
                % totalBitCount = totalBitCount - bitPerRow(x);
            end
        end

        function ROI = getROIarea(obj, bboxes)
            bboxPoints = bbox2points(bboxes(1, :));
            heightstart = bboxPoints(1,1);
            heightend = bboxPoints(2,1);
            widthstart = bboxPoints(1,2);
            widthend = bboxPoints(3,2);
            rowstart = floor(heightstart / obj.blockSize);
            rowend = floor(heightend / obj.blockSize) + 1;
            colstart = floor(widthstart / obj.blockSize);
            colend = floor(widthend / obj.blockSize) + 1;
            ROI = [rowstart rowend colstart colend]; 
        end

        function [QPs, splitStr, motionVectors, approximatedBlocks] = getVariableBlocksPerRow(obj, r, n, FastME, previousQPs, frameType)
            % calculate sub blocks on per row base with various initial QP
            splitStr = '';
            QPs = [];
            motionVectors = {};
            approximatedBlocks = {};
            
            if obj.QP_delta ~= 0
                faceDetector =  vision.CascadeObjectDetector;
                faceDetector.MergeThreshold = 4;
                bboxes = step(faceDetector, obj.currFrame.frameData);
                if isempty(bboxes)
                    obj.ROI = [0 0 0 0];
                else
                    obj.ROI = obj.getROIarea(bboxes);
                end
            end

            if obj.nRefFrames > 1
                mvL = 3;
            else
                mvL = 2;
            end
            rowCount = obj.currFrame.height / obj.blockSize;
            for x = 1 : obj.currFrame.height / obj.blockSize
                QP = obj.rc.getEstimatedQP(frameType, rowCount);
                QPs = [QPs, QP];
                bitCount = 0;
                prevMV = zeros(1, mvL);
                if obj.QP_delta ~= 0
                    if x >= obj.ROI(1) && x <= obj.ROI(2)
                        QP = QP - obj.QP_delta;
                    else
                        QP = QP + obj.QP_delta;
                    end
                end
                subBlocks = obj.createSubBlocksPerRow(x, r, n, FastME, QP);
                for y = 1 : obj.currFrame.width / obj.blockSize
                    [s, mv, res] = obj.getSplittedData(subBlocks, obj.blockSize, 1, y);

                    mv = entropy(mv, obj.blockSize).decode(0);
                    temp = [];
                    for m = 1 : mvL : length(mv)
                        temp = [temp, mv(m : m + mvL - 1) - prevMV];
                        prevMV = mv(m : m + mvL - 1);
                    end
                    entropyedMV = entropy(temp, obj.blockSize).encode(0, 0);

                    if y == 1
                        res = entropy(QP - previousQPs(x), obj.blockSize).encode(0, 0) + res;
                    end

                    splitStr = [splitStr, s];
                    motionVectors{x, y} = entropyedMV;
                    approximatedBlocks{x, y} = res;
                    bitCount = bitCount + strlength(s) + strlength(entropyedMV) + strlength(res);
                end
                obj.rc = obj.rc.updateRemainingBit(bitCount);
                rowCount = rowCount - 1;
            end
        end

        function [bitPerRow, splitStr, motionVectors, approximatedBlocks] = getVariableBlocksBitCounts(obj, r, n, QP)
            subBlocks = obj.createSubBlocks(r, n, 1, QP);

            splitStr = '';
            motionVectors = {};
            approximatedBlocks = {};
            bitPerRow = [];
            if obj.nRefFrames > 1
                mvL = 3;
            else
                mvL = 2;
            end
            for x = 1 : obj.currFrame.height / obj.blockSize
                bitCount = 0;
                prevMV = zeros(1, mvL);
                for y = 1 : obj.currFrame.width / obj.blockSize
                    [s, mv, res] = obj.getSplittedData(subBlocks, obj.blockSize, x, y);

                    mv = entropy(mv, obj.blockSize).decode(0);
                    temp = [];
                    for m = 1 : mvL : length(mv)
                        temp = [temp, mv(m : m + mvL - 1) - prevMV];
                        prevMV = mv(m : m + mvL - 1);
                    end
                    entropyedMV = entropy(temp, obj.blockSize).encode(0, 0);

                    splitStr = [splitStr, s];
                    motionVectors{x, y} = entropyedMV;
                    approximatedBlocks{x, y} = res;
                    bitCount = bitCount + strlength(s) + strlength(entropyedMV) + strlength(res);
                end
                bitPerRow = [bitPerRow, bitCount];
            end
        end

        function [splitStr, motionVectors, approximatedBlocks] = getVariableBlocks(obj, r, n, FastME)
            subBlocks = obj.createSubBlocks(r, n, FastME, obj.QP);

            splitStr = '';
            motionVectors = {};
            approximatedBlocks = {};
            for x = 1 : obj.currFrame.height / obj.blockSize
                for y = 1 : obj.currFrame.width / obj.blockSize
                    [s, mv, res] = obj.getSplittedData(subBlocks, obj.blockSize, x, y);
                    splitStr = [splitStr, s];
                    motionVectors{x, y} = mv;
                    approximatedBlocks{x, y} = res;
                end
            end

            if obj.isDifferential
                motionVectors = obj.getDifferentialMV(motionVectors);
            end
        end

        function [splitStr, mvs, residuals] = getSplittedData(obj, subblocks, i, x, y)
            splitted = obj.shouldSplit(subblocks, i, x, y);
            splitStr = num2str(splitted);
            if splitted == 1
                newI = i / 2;
                [s1, mv1, res1] = obj.getSplittedData(subblocks, newI, 2*x-1, 2*y-1);
                [s2, mv2, res2] = obj.getSplittedData(subblocks, newI, 2*x-1, 2*y);
                [s3, mv3, res3] = obj.getSplittedData(subblocks, newI, 2*x, 2*y-1);
                [s4, mv4, res4] = obj.getSplittedData(subblocks, newI, 2*x, 2*y);
                mvs = [mv1, mv2, mv3, mv4];
                splitStr = [splitStr, s1, s2, s3, s4];
                residuals = {res1, res2, res3, res4};
                residuals = cell2mat(residuals);
            else
                sb = subblocks(i);
                sb = sb{1};
                mvs = sb{1}{x, y};
                residuals = sb{2}{x, y};
            end
        end


        function split = shouldSplit(obj, subblocks, i, x, y)
            % minimum blockSize is 2^2 = 4
            if i <= obj.subBlockSize
                split = 0;
            else
                v = subblocks(i);
                v = v{1};
                RDO = obj.getRDO(v{3}{x, y}, v{4}{x, y});

                subI = i / 2;
                subV = subblocks(subI);
                subV = subV{1};
                subRDO = obj.getRDO(subV{3}{2 * x - 1, 2 * y - 1}, subV{4}{2 * x - 1, 2 * y - 1});
                subRDO = subRDO + obj.getRDO(subV{3}{2 * x - 1, 2 * y}, subV{4}{2 * x - 1, 2 * y});
                subRDO = subRDO + obj.getRDO(subV{3}{2 * x, 2 * y - 1}, subV{4}{2 * x, 2 * y - 1});
                subRDO = subRDO + obj.getRDO(subV{3}{2 * x, 2 * y}, subV{4}{2 * x, 2 * y});
                if subRDO < RDO
                    split = 1;
                else
                    split = 0;
                end
            end
        end

        function subBlocks = createSubBlocksPerRow(obj, x, r, n, FastME, QP)
            i = obj.blockSize;
            q = QP;
            currX = x;
            rowCount = 1;
            while i >= obj.subBlockSize
                fme = obj.getFrameMotionEstimator(i);
                [SADs, motionVector] = fme.getBestPredictedBlocksPerRow(currX, r, 0, FastME, rowCount);
                entropyedMV = entropy(motionVector, i).encode(0, 1);

                approximatedBlocks = fme.getApproximatedResidualBlocksPerRow(motionVector, n, currX, rowCount);
                dctTransformed = fme.getDCTBlocks(approximatedBlocks);
                QTC = fme.getQuatizedBlocks(dctTransformed, q);
                entropyedQTC = entropy(QTC, i).encode(1, 1);
                entropyedQTC = entropy(entropyedQTC, i).encode(0, 1);

                % bitCount
                bitCount = obj.getBitCount(entropyedMV, entropyedQTC);

                value = {entropyedMV, entropyedQTC, SADs, bitCount};
                if exist("subBlocks", "var")
                    subBlocks(i) = {value};
                else
                    subBlocks = dictionary(i, {value});
                end

                i = i / 2;
                q = q - 1;
                if q < 0
                    q = 0;
                end
                currX = currX * 2 - 1;
                rowCount = rowCount + 1;
            end
        end

        function subBlocks = createSubBlocks(obj, r, n, FastME, QP)
            i = obj.blockSize;
            q = QP;
            % smallest blockSize is 2^2 = 4
            while i >= obj.subBlockSize
                fme = obj.getFrameMotionEstimator(i);
                [SADs, motionVector] = fme.getBestPredictedBlocks(r, 0, FastME);
                entropyedMV = entropy(motionVector, i).encode(0, 1);

                approximatedBlocks = fme.getApproximatedResidualBlocks(motionVector, n);
                dctTransformed = fme.getDCTBlocks(approximatedBlocks);
                QTC = fme.getQuatizedBlocks(dctTransformed, q);
                entropyedQTC = entropy(QTC, i).encode(1, 1);
                entropyedQTC = entropy(entropyedQTC, i).encode(0, 1);

                % bitCount
                bitCount = obj.getBitCount(entropyedMV, entropyedQTC);

                value = {entropyedMV, entropyedQTC, SADs, bitCount};
                if exist("subBlocks", "var")
                    subBlocks(i) = {value};
                else
                    subBlocks = dictionary(i, {value});
                end

                i = i / 2;
                q = q - 1;
                if q < 0
                    q = 0;
                end
            end
        end

        function [rdCost, mv, residual, entropyedMV] = getBlockRDCost(obj, x, y, currI, r, n, FastME, QP, prevMV)
            fme = RCMotionEstimator(obj.currFrame, obj.refFrames, obj.nRefFrames, currI);
            currBlock = obj.currFrame.frameData(1 + (x - 1) * currI : x * currI, 1 + (y - 1) * currI : y * currI);
            frameX = 1 + (x - 1) * currI;
            frameY = 1 + (y - 1) * currI;
            [diff, mv, residual] = fme.getBestBlockWithNN(currBlock, frameX, frameY, r, currI, prevMV, n, QP, 1);
            if obj.isDifferential
                diffMV = mv - prevMV;
            else
                diffMV = mv;
            end
            entropyedMV = entropy(diffMV, currI).encode(0, 0);
            residual = cell2mat(residual);
            rdCost = obj.getRDO(diff, strlength(entropyedMV) + strlength(residual));
        end

        function [splitS, entropyedMV, entropyedResidual, prevMV] = getVariableBlockWithRef(obj, r, n, FastME, QP, x, y, prevMV)
            % return splitString for current Block
            [rdCost, mv, residual, entropyedMV] = obj.getBlockRDCost(x, y, obj.blockSize, r, n, FastME, QP, prevMV);

            % rd cost for sub-blocks
            subI = obj.blockSize / 2;
            currQP = QP - 1;
            if currQP < 0
                currQP = 0;
            end
            [rdCost1, mv1, residual1, entropyedMV1] = obj.getBlockRDCost(2 * x - 1, 2 * y - 1, subI, r, n, FastME, currQP, prevMV);
            [rdCost2, mv2, residual2, entropyedMV2] = obj.getBlockRDCost(2 * x - 1, 2 * y, subI, r, n, FastME, currQP, mv1);
            [rdCost3, mv3, residual3, entropyedMV3] = obj.getBlockRDCost(2 * x, 2 * y - 1, subI, r, n, FastME, currQP, mv2);
            [rdCost4, mv4, residual4, entropyedMV4] = obj.getBlockRDCost(2 * x, 2 * y, subI, r, n, FastME, currQP, mv3);

            if rdCost < rdCost1 + rdCost2 + rdCost3 + rdCost4
                splitS = "0";
                entropyedMV = entropyedMV;
                entropyedResidual = residual;
                prevMV = mv;
            else
                splitS = "10000";
                entropyedMV = entropyedMV1 + entropyedMV2 + entropyedMV3 + entropyedMV4;
                entropyedResidual = [residual1, residual2, residual3, residual4];
                prevMV = mv4;
            end
        end

        function [splitS, entropyedMV, entropyedResidual] = getVariableBlock(obj, r, n, FastME, QP, x, y)
            prevMV = zeros(1, 2);
            % return splitString for current Block
            [rdCost, mv, residual, entropyedMV] = obj.getBlockRDCost(x, y, obj.blockSize, r, n, FastME, QP, prevMV);

            % rd cost for sub-blocks
            subI = obj.blockSize / 2;
            currQP = QP - 1;
            if currQP < 0
                currQP = 0;
            end
            [rdCost1, mv1, residual1, entropyedMV1] = obj.getBlockRDCost(2 * x - 1, 2 * y - 1, subI, r, n, FastME, currQP, prevMV);
            [rdCost2, mv2, residual2, entropyedMV2] = obj.getBlockRDCost(2 * x - 1, 2 * y, subI, r, n, FastME, currQP, prevMV);
            [rdCost3, mv3, residual3, entropyedMV3] = obj.getBlockRDCost(2 * x, 2 * y - 1, subI, r, n, FastME, currQP, prevMV);
            [rdCost4, mv4, residual4, entropyedMV4] = obj.getBlockRDCost(2 * x, 2 * y, subI, r, n, FastME, currQP, prevMV);

            if rdCost < rdCost1 + rdCost2 + rdCost3 + rdCost4
                splitS = "0";
                entropyedMV = entropyedMV;
                entropyedResidual = residual;
            else
                splitS = "10000";
                entropyedMV = entropyedMV1 + entropyedMV2 + entropyedMV3 + entropyedMV4;
                entropyedResidual = [residual1, residual2, residual3, residual4];
            end
        end

        function fme = getFrameMotionEstimator(obj, i)
            currFrame = frameBlocks(obj.currFrame.frameData, i);
            referenceFrames = {};
            for f = 1 : length(obj.refFrames)
                referenceFrames{f} = frameBlocks(obj.refFrames{f}.frameData, i);
            end
            if obj.FMEEnable == 1
                fme = fractionalMotionEstimation(currFrame, referenceFrames, obj.nRefFrames);
            else
                fme = quantizedMotionEstimator(currFrame, referenceFrames, obj.nRefFrames);
            end
        end

        function bitCount = getBitCount(obj, data, data2)
            bitCount = {};
            s = size(data);
            for x = 1 : s(1)
                for y = 1 : s(2)
                    bitCount{x, y} = strlength(data{x, y}) + strlength(data2{x, y});
                end
            end 
        end

        function cost = getRDO(obj, D, R)
            lambda = 2.2 * pow2((obj.QP - 12) / 3);
            cost = D + lambda * R;
        end


        function [coloredY, reconstructedY] = getReconstructedFrameWithQP(obj, splitStr, entropyedMV, entropyedResidual, width, height, FMEEnable, previousQPs)
            vf = vbsFrame(obj.refFrames, splitStr, entropyedMV, entropyedResidual, width, height, obj.blockSize, obj.QP, obj.isDifferential, obj.nRefFrames, FMEEnable);
            [coloredY, reconstructedY, QPs] = vf.reconstructedFrameWithQP(previousQPs);
        end


        function [coloredY, reconstructedY] = getReconstructedFrame(obj, splitStr, entropyedMV, entropyedResidual, width, height, FMEEnable)
            vf = vbsFrame(obj.refFrames, splitStr, entropyedMV, entropyedResidual, width, height, obj.blockSize, obj.QP, obj.isDifferential, obj.nRefFrames, FMEEnable);
            [coloredY, reconstructedY] = vf.reconstructedFrame();
        end

        function reconstructedBlock = getReconstructedBlock(obj, splitStr, entropyedMV, entropyedResidual, width, height, prevMV, x, y)
            vf = vbsFrame(obj.refFrames, char(splitStr), entropyedMV, entropyedResidual, width, height, obj.blockSize, obj.QP, obj.isDifferential, obj.nRefFrames, 1);
            [idx, splitS] = vf.getNextSplitString(1, obj.blockSize, []);
            mv = entropy(entropyedMV, obj.blockSize).decode(0);
            residual = entropy(entropyedResidual, obj.blockSize).decode(0);
            [c, reconstructedBlock, p] = vf.getReconstructedBlock(splitS, mv, residual, x, y, prevMV, 2, obj.FMEEnable, obj.QP);
        end

        function [mode, recontructedBlock] = getIntraMode(obj, splitStr, block, hRow, vRow)
            mode = "";
            vPredicted = repmat(vRow, obj.blockSize, 1);
            hPredicted = repmat(hRow, 1, obj.blockSize);
            intra = vbsIntraFrame(block, 0, 0, obj.blockSize, 1, splitStr);
            vf = vbsFrame(obj.refFrames, char(splitStr), "", "", 0, 0, obj.blockSize, obj.QP, obj.isDifferential, obj.nRefFrames, 1);

            [idx, splitBlocks] = vf.getNextSplitString(1, obj.blockSize, []);
            directions = [];
            direction = 0;
            m = 1;
            n = 1;
            previousI = -1;
            recontructedBlock = zeros(obj.blockSize, obj.blockSize);
            for s = 1 : length(splitBlocks)
                currI = splitBlocks(s);
                tempBlock = block(m : m + currI - 1, n : n + currI - 1);
                tempV = vPredicted(m : m + currI - 1, n : n + currI - 1);
                tempH = hPredicted(m : m + currI - 1, n : n + currI - 1);

                v = intra.getMAE(tempBlock, tempV);
                h = intra.getMAE(tempBlock, tempH);
                if v < h
                    mode = mode + string(1);
                    recontructedBlock(m : m + currI - 1, n : n + currI - 1) = tempV;
                else
                    mode = mode + string(0);
                    recontructedBlock(m : m + currI - 1, n : n + currI - 1) = tempH;
                end

                [m, n, direction, directions] = vf.getNewCoord(currI, previousI, directions, direction, m, n);
                previousI = currI;
            end
        end

        function entropyed = getEntropyedModes(obj, modes)
            entropyed = "";
            prev = "0";
            for x = 1 : size(modes, 1)
                for y = 1 : size(modes, 2)
                    tempM = char(modes(x, y));
                    for c = 1 : length(tempM)
                        if tempM(c) == prev
                            entropyed = entropyed + entropy(0, 0).encode(0, 0);
                        else
                            entropyed = entropyed + entropy(1, 0).encode(0, 0);
                        end
                        prev = tempM(c);
                    end
                end
            end
        end

        function obj = updateRefFrame(obj, rowData, row)
            refFrame = obj.refFrames{1};
            colNumbers = refFrame.width / obj.blockSize;
            refFrame.frameData(1 + (row - 1) * obj.blockSize : row * obj.blockSize, :) = rowData;
            for col = 1 : colNumbers
                refFrame.blocks(row, col) = {rowData(:, 1 + (col - 1) * obj.blockSize : col * obj.blockSize)};
            end
            obj.refFrames{1} = refFrame;
        end
        function mvs = getDifferentialMV(obj, motionVectors)
            if obj.nRefFrames > 1
                mvL = 3;
            else
                mvL = 2;
            end
            mvSize = size(motionVectors);
            mvs = {};
            for x = 1 : mvSize(1)
                prevMV = zeros(1, mvL);
                for y = 1 : mvSize(2)
                    temp = [];
                    mv = entropy(motionVectors{x, y}, obj.blockSize).decode(0);
                    for m = 1 : mvL : length(mv)
                        temp = [temp, mv(m : m + mvL - 1) - prevMV];
                        prevMV = mv(m : m + mvL - 1);
                    end
                    mvs{x, y} = entropy(temp, obj.blockSize).encode(0, 0);
                end
            end
        end
    end
end