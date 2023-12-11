classdef differentialCode
    %differentialCode Summary of this class goes here
    properties
        isMode;
        mvLen;
    end

    methods
        function obj = differentialCode(isMode, nRefFrames)
            obj.isMode = isMode;
            if nRefFrames > 1
                obj.mvLen = 3;
            else
                obj.mvLen = 2;
            end
        end

        function output = encode(obj, data)
            if obj.isMode == 1
                output = obj.encodeModes(data);
            else
                output = obj.encodeMV(data);
            end
        end

        function output = decode(obj, data)
            if obj.isMode == 1
                output = obj.decodeModes(data);
            else
                output = obj.decodeMV(data);
            end
        end

        function output = encodeMV(obj, data)
            data = double(data);
            s = size(data);
            output = zeros(s(1), s(2));
            for x = 1 : s(1)
                prevMV = zeros(1, obj.mvLen);
                for y = 1 : obj.mvLen : s(2)
                    output(x, y : y + obj.mvLen - 1) = data(x, y : y + obj.mvLen - 1) - prevMV;
                    prevMV = data(x, y : y + obj.mvLen - 1);
                end
            end
        end

        function output = encodeModes(obj, data)
            prevMode = 0; % start from horizontal
            s = size(data);
            output = zeros(s(1), s(2));
            for x = 1 : s(1)
                for y = 1 : s(2)
                    if data(x, y) == prevMode
                        output(x, y) = 0; % same as before
                    else
                        output(x, y) = 1; % change
                        prevMode = data(x, y);
                    end
                end
            end
        end

        function output = decodeModes(obj, data)
            mode = 0; % from Horizontal
            s = size(data);
            output = zeros(s(1), s(2));
            for x = 1 : s(1)
                for y = 1 : s(2)
                    if data(x, y) == 1 % change
                        mode = 1 - mode;
                    end
                    output(x, y) = mode; 
                end
            end
        end

        function output = decodeMV(obj, data)
            s = size(data);
            output = zeros(s(1), s(2));
            for x = 1 : s(1)
                prevMV = zeros(1, obj.mvLen);
                for y = 1 : obj.mvLen : s(2)
                    output(x, y : y + obj.mvLen - 1) = data(x, y : y + obj.mvLen - 1) + prevMV;
                    prevMV = output(x, y : y + obj.mvLen - 1);
                end
            end
        end
    end

end