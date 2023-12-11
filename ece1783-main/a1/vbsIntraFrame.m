classdef vbsIntraFrame < intraFrame
    properties
        isDifferential;
        splitStr;
    end

   methods
    function obj = vbsIntraFrame(frameData, width, height, blockSize, isDifferential, splitStr)
        obj = obj@intraFrame(frameData, width, height, blockSize);
        obj.isDifferential = isDifferential;
        obj.splitStr = splitStr;
    end

    function [modes, predictedFrame, diffmodes] = predictVBS(obj)
        predictedFrame = {};
        modes = [];
        vf = vbsFrame(0, obj.splitStr, 0, 0, obj.width, obj.height, obj.blockSize, 0, 0, 0, 0); 
        splitBlocks = vf.getSplitStrBlocks();

        xBlocks = obj.width / obj.blockSize;
        for x = 1 : obj.height / obj.blockSize
            for y = 1 : obj.width / obj.blockSize
                splitS = cell2mat(splitBlocks((x - 1) * xBlocks + y));
                [mode, predictedFrame{x, y}] = obj.predictBlock(vf, splitS, x, y);
                modes = [modes, mode];
            end
        end

        if obj.isDifferential
            modes = differentialCode(1, 0).encode(modes);
        end
        modes = entropy(modes, 0).encode(0, 0);
        predictedFrame = uint8(cell2mat(predictedFrame));
    end

    function predictedFrame = getPredictedVBS(obj, modes)
        modes = entropy(modes, 0).decode(0, 0);
        if obj.isDifferential == 1
            modes = differentialCode(1, 0).decode(modes);
        end

        predictedFrame = {};
        vf = vbsFrame(0, obj.splitStr, 0, 0, obj.width, obj.height, obj.blockSize, 0, 0, 0, 0); 
        splitBlocks = vf.getSplitStrBlocks();
        xBlocks = obj.width / obj.blockSize;
        modeIdx = 1;
        for x = 1 : obj.height / obj.blockSize
            for y = 1 : obj.width / obj.blockSize
                splitS = cell2mat(splitBlocks((x - 1) * xBlocks + y));
                [modeIdx, predictedFrame{x, y}] = obj.getPredictedBlock(vf, splitS, x, y, modes, modeIdx);
            end
        end
        predictedFrame = uint8(cell2mat(predictedFrame));
    end

    function [modeIdx, data] = getPredictedBlock(obj, vf, splitS, x, y, modes, modeIdx)
        frameX = (x - 1) * obj.blockSize;
        frameY = (y - 1) * obj.blockSize;
        m = 1;
        n = 1;
        data = zeros(obj.blockSize, obj.blockSize);
        mode = [];
        directions = [];
        direction = 0;
        previousI = -1;
        for s = 1 : length(splitS)
            currI = splitS(s);
            mode = modes(modeIdx);
            xIdx = 1 + (frameX + m - 1) / currI;
            yIdx = 1 + (frameY + n - 1) / currI;
            if mode == 0
                data(m : m + currI - 1, n : n + currI - 1) = obj.getHPredictedBlock(xIdx, yIdx, currI);
            else
                data(m : m + currI - 1, n : n + currI - 1) = obj.getVPredictedBlock(xIdx, yIdx, currI);
            end
            modeIdx = modeIdx + 1;
            [m, n, direction, directions] = vf.getNewCoord(currI, previousI, directions, direction, m, n);
            previousI = currI;
        end
    end

    function [mode, data] = predictBlock(obj, vf, splitS, x, y)
        frameX = (x - 1) * obj.blockSize;
        frameY = (y - 1) * obj.blockSize;
        m = 1;
        n = 1;
        data = zeros(obj.blockSize, obj.blockSize);
        mode = [];
        directions = [];
        direction = 0;
        previousI = -1;
        for s = 1 : length(splitS)
            currI = splitS(s);
            [mode(s), data(m : m + currI - 1, n : n + currI - 1)] = obj.predictSubBlock(currI, frameX + m, frameY + n);
            [m, n, direction, directions] = vf.getNewCoord(currI, previousI, directions, direction, m, n);
            previousI = currI;
        end
    end

    function [mode, data] = predictSubBlock(obj, currI, m, n)
        block = obj.frame(m : m + currI - 1, n : n + currI - 1);
        xIdx = 1 + (m - 1) / currI;
        yIdx = 1 + (n - 1) / currI;
        vPredicted = obj.getVPredictedBlock(xIdx, yIdx, currI);
        v = obj.getMAE(block, vPredicted);
        hPredicted = obj.getHPredictedBlock(xIdx, yIdx, currI);
        h = obj.getMAE(block, hPredicted);
        if v < h
            mode = 1;
            data = vPredicted;
        else
            mode = 0;
            data = hPredicted;
        end
    end
   end
end