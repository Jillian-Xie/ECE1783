classdef frameBlocks
    %frameBlocks Summary of this class goes here
    properties
        frameData;
        width;
        height;
        blocks;
    end

    methods
        function obj = frameBlocks(frameData, blockSize)
            obj = obj.addPaddings(frameData, blockSize);
        end

        function obj = addPaddings(obj, original, blockSize)
            s = size(original);
            height = s(1);
            width = s(2);
            heightBlock = ceil(height / blockSize);
            widthBlock = ceil(width / blockSize);
            if mod(height, blockSize) ~= 0
                padding = int32(128 * ones(blockSize - mod(height, blockSize), width));
                original(height + 1 : heightBlock * blockSize, :) = padding;
                height = heightBlock * blockSize;
            end

            if mod(width, blockSize) ~= 0
                padding = int32(128 * ones(height, blockSize - mod(width, blockSize)));
                original(:, width + 1 : widthBlock * blockSize) = padding;
                width = widthBlock * blockSize;
            end

            obj.height = height;
            obj.width = width;
            obj.frameData = original;
            obj.blocks = mat2cell(original, blockSize * int32(ones(1, heightBlock)), blockSize * int32(ones(1, widthBlock)));
        end
    end

end