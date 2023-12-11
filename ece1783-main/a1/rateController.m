classdef rateController
    %rateController Summary of this class goes here
    properties
        config;
        remainingBit;
        scalingFactor;
    end

    methods
        function obj = rateController(configFile)
            obj.remainingBit = 0;
            obj.scalingFactor = 1;
            fid = fopen(configFile, "r");
            obj.config = dictionary("i", {str2num(fgetl(fid))});
            obj.config("p") = {str2num(fgetl(fid))};
            fclose(fid);
        end

        function bitCount = getBitPerFrame(obj, targetBR, nFrames)
            bitCount = str2double(regexp(targetBR,"^[\.0-9]*","match"));
            unit = regexp(targetBR,"(mbps)|(bps)|(kbps)$","match");
            if unit == "kbps"
                bitCount = bitCount * 1e3;
            elseif unit == "mbps"
                bitCount = bitCount * 1e6;
            end
            bitCount = floor(bitCount / 30);
        end

        function obj = resetBitPerFrame(obj, bitCount)
            obj.remainingBit = bitCount;
        end

        function obj = updateRemainingBit(obj, used)
            obj.remainingBit = obj.remainingBit - used;
        end

        function QP = getEstimatedQP(obj, frameType, rowCount)
            rowPerBit = floor(obj.remainingBit / rowCount);
            frameConfig = obj.config(frameType);
            QP = 0;
            while QP <= 10 && frameConfig{1}(QP + 1) > rowPerBit
                QP = QP + 1;
            end
        end

        function QP = getEstimatedPropQP(obj, frameType, proportion)
            rowPerBit = round(obj.remainingBit * proportion);
            frameConfig = obj.config(frameType);
            QP = 0;
            while QP <= 10 && frameConfig{1}(QP + 1) * obj.scalingFactor > rowPerBit
                QP = QP + 1;
            end
        end

        function obj = setScalingFactor(obj, QP, bitsPerRow, frameType)
            frameConfig = obj.config(frameType);
            obj.scalingFactor = bitsPerRow / frameConfig{1}(QP + 1);
        end

        function bitCount = getEstimatePBit(obj, QP)
            frameConfig = obj.config("p");
            bitCount = frameConfig{1}(QP + 1);
        end
    end

end