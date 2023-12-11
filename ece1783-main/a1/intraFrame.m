classdef intraFrame
    %intraFrame Summary of this class goes here
    properties
        frame;
        blockSize;
        width;
        height;
    end

    methods
        function obj = intraFrame(frameData, width, height, blockSize)
            obj.frame = frameData;
            obj.width = width;
            obj.height = height;
            obj.blockSize = blockSize;
        end

        function [modes, predictedFrame] = predict(obj)
            predictedFrame = {};
            modes = {};
            frameBlock = frameBlocks(obj.frame, obj.blockSize);
            blocks = frameBlock.blocks;
            s = size(blocks);
            for m = 1 : s(1)
                for n = 1 : s(2)
                    block = cell2mat(blocks(m, n));
                    % get Vertical MAE
                    vPredicted = obj.getVPredicted(m, n);
                    v = obj.getMAE(block, vPredicted);
                    % get Horizontal MAE
                    hPredicted = obj.getHPredicted(m, n);
                    h = obj.getMAE(block, hPredicted);

                    if v < h
                        modes{m, n} = 1;
                        predictedFrame{m, n} = vPredicted;
                    else
                        modes{m, n} = 0;
                        predictedFrame{m, n} = hPredicted;
                    end
                end
            end
            modes = cell2mat(modes);
            predictedFrame = cell2mat(predictedFrame);
        end

        function predicted = getVPredictedBlock(obj, m, n, s)
            if m == 1
                vPredicted = uint8(128 * ones(1, s));
            else
                vPredicted = obj.frame((m - 1) * s, 1 + (n - 1) * s : n * s);
            end
            predicted = repmat(vPredicted, s, 1);
        end

        function predicted = getVPredicted(obj, m, n)
            predicted = obj.getVPredictedBlock(m, n, obj.blockSize);
        end

        function predicted = getHPredictedBlock(obj, m, n, s)
            if n == 1
                hPredicted = uint8(128 * ones(s, 1));
            else
                hPredicted = obj.frame(1 + (m - 1) * s : m * s, (n - 1) * s);
            end
            predicted = repmat(hPredicted, 1, s);
        end

        function predicted = getHPredicted(obj, m, n)
            predicted = obj.getHPredictedBlock(m, n, obj.blockSize);
        end

        function mae = getMAE(obj, curr, predicted)
            blockdiff = abs(double(curr) - double(predicted));
            mae = double(sum(blockdiff, "all")) / (obj.blockSize * obj.blockSize);
        end

        function predictedFrame = getPredicted(obj, mode, numBlockHeight, numBlockWidth)
            predictedFrame = {};
            for m = 1 : numBlockHeight
                for n = 1 : numBlockWidth
                    if mode(m, n) == 0
                        % horizontal
                        predictedFrame{m, n} = obj.getHPredicted(m, n);
                    elseif mode(m, n) == 1
                        % vertical
                        predictedFrame{m, n} = obj.getVPredicted(m, n);
                    end
                end
            end
            predictedFrame = cell2mat(predictedFrame);
        end
    end

end