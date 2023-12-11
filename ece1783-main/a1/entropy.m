classdef entropy
    %entropy Summary of this class goes here
    properties
        blocks;
        blockSize;
    end

    methods
        function obj = entropy(blocks, blockSize)
            obj.blocks = blocks;
            obj.blockSize = blockSize;
        end

        function output = encode(obj, isRLE, isBlock)
            if isRLE
                output = obj.encodeRLE();
            else
                output = obj.encodeExpGolomb(isBlock);
            end
        end

        function output = decode(obj, isRLE, widthLimit)
            if isRLE
                output = obj.decodeRLE(widthLimit);
            else
                output = obj.decodeExpGolomb();
            end
        end

        function output = encodeExpGolomb(obj, isBlock)
            s = size(obj.blocks);
            output = {};
            isCellBlock = iscell(obj.blocks);
            for n = 1 : s(2)
                for m = 1 : s(1)
                    if isCellBlock
                        data= double(cell2mat(obj.blocks(m, n)));
                    else
                        data = double(obj.blocks(m, n));
                    end
                    output{m, n} = obj.getExpGolombMatrix(data);
                end
            end
            if isBlock == 0
                output = string(output);
                output = sprintf("%s", output);
            end
        end

        function output = getExpGolombMatrix(obj, mat)
            output = arrayfun(@(x) obj.getExpGolombValue(x), mat, 'UniformOutput', false);
            output = sprintf('%s', string(output));
        end

        function output = getExpGolombValue(obj, value)
            if value > 0
                value = 2 * value - 1;
            else
                value = -2 * value;
            end
            bitCount = floor(log2(value + 1));
            output = dec2bin(value + 1, bitCount);
            output = [sprintf('%d', zeros(1, bitCount)), output];
        end

        function numbers = decodeExpGolomb(obj)
            i = 1;
            numbers = [];
            s = obj.blocks;
            if isstring(s)
                s = char(s);
            end
            while i <= length(s)
                bitCount = 0;
                while s(i) == '0'
                    i = i + 1;
                    bitCount = bitCount + 1;
                end
                value = bin2dec(s(i : i + bitCount)) - 1;
                if rem(value, 2) == 0
                    value = -1 * ceil(value / 2);
                else
                    value = ceil(value / 2);
                end
                numbers = [numbers, value];
                i = i + bitCount + 1;
            end
        end

        function output = encodeRLE(obj)
            s = size(obj.blocks);
            output = {};
            for m = 1 : s(1)
                for n = 1 : s(2)
                    % 1) reorder in diagonal order
                    reordered = obj.reorderBlock(cell2mat(obj.blocks(m, n)));
                    % 2) RLE
                    encodedArray = obj.RLE(reordered);
                    output{m, n} = encodedArray;
                end
            end
        end

        function reorderedArray = reorderBlock(obj, block)
            direction = 1; % 1: y -> 1; 0: y -> 4
            reoderedArray = zeros(1, obj.blockSize * obj.blockSize);
            x = 1;
            y = 1;
            for i = 1 : obj.blockSize * obj.blockSize
                reorderedArray(1, i) = block(x, y);
                [x, y, direction] = obj.getReorderIdx(x, y, direction);
            end
        end

        function encoded = RLE(obj, array)
            % FIXME do not encode 0 if length(0) <= 2
            encoded = [];
            startIdx = 0;
            zeroCount = 0;
            for i = 1 : length(array)
                if array(i) == 0
                    if zeroCount >= 2 && startIdx ~= 0
                        encoded = [encoded, - (i - zeroCount - startIdx), array(startIdx : i - zeroCount - 1)];
                        startIdx = 0;
                    end
                    zeroCount = zeroCount + 1;
                else
                    if zeroCount <= 2 && zeroCount ~= 0 && startIdx == 0
                        startIdx = i - zeroCount;
                    end
                    if startIdx == 0
                        startIdx = i;
                    end
                    if zeroCount > 2
                        encoded = [encoded, zeroCount];
                        zeroCount = 0;
                    elseif zeroCount ~= 0
                        zeroCount = 0;
                    end
                end
            end
            if startIdx > 0
                l = length(array) - zeroCount - startIdx + 1;
                encoded = [encoded, - l, array(startIdx : startIdx + l - 1)];
            end

            if zeroCount ~= 0
                encoded = [encoded, 0];
            end
        end

        function [block, start] = decodeRLEBlock(obj, start)
            data = obj.blocks;
            blockLength = obj.blockSize * obj.blockSize;
            block = [];
            while start <= length(data)
                if data(start) == 0
                    block = [block, zeros(1, blockLength - length(block))];
                    start = start + 1;
                    break
                elseif data(start) < 0
                    l = abs(data(start));
                    block = [block, data(start + 1 : start + l)];
                    start = start + l + 1;
                elseif data(start) > 0
                    block = [block, zeros(1, data(start))];
                    start = start + 1;
                end

                if length(block) == blockLength
                    break
                end
            end
        end

        function output = decodeRLE(obj, widthLimit)
            m = 1;
            n = 1;
            output = {};
            i = 1;
            while i <= length(obj.blocks)
                previ = i;
                [block, i] = obj.decodeRLEBlock(i);
                output{m, n} = obj.reorderToBlock(block);
                if m == widthLimit
                    m = 1;
                    n = n + 1;
                else
                    m = m + 1;
                end

            end
        end

        function block = reorderToBlock(obj, data)
            direction = 1;
            m = 1;
            n = 1;
            block = zeros(obj.blockSize, obj.blockSize);

            for i = 1 : length(data)
                block(m, n) = data(i);
                [m, n, direction] = obj.getReorderIdx(m, n, direction);
            end
        end

        function [x, y, direction] = getReorderIdx(obj, x, y, direction)
            if direction == 1 && y == 1
                y = x + 1;
                if y > obj.blockSize
                    direction = 0;
                    x = 2;
                    y = obj.blockSize;
                else
                    x = 1;
                end
            elseif direction == 0 && x == obj.blockSize
                x = y + 1;
                y = obj.blockSize;
            else
                x = x + 1;
                y = y - 1;
            end
        end
    end

end