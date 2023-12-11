classdef yOnlyVideo
    %yOnlyVideo Summary of this class goes here
    properties
        width;
        height;
        nframes; 
        frameLength;
        yframes;
        uframes;
        vframes;
    end

    methods
        function obj = yOnlyVideo(filename, width, height, nframes)
            %yOnlyVideo Construct an instance of this class
            obj.width = width;
            obj.height = height;
            obj.nframes = nframes;
            obj.yframes = uint8(zeros(height, width, nframes));
            obj.frameLength = obj.width * obj.height * 1.5;
            obj = readYUV(obj, filename);
        end

        function obj = readYUV(obj,filename)
            stream = fread(fopen(filename, 'rb'), '*uchar');
            yLength = obj.width * obj.height;
            for i = 1:obj.nframes
                frameData = stream((i - 1) * obj.frameLength + 1 : obj.frameLength * i);
                obj.yframes(:, :, i) = uint8(reshape(frameData(1 : yLength), obj.width, obj.height)');
                obj.uframes(:, :, i) = uint8(reshape(frameData(1 + yLength : 1.25 * yLength), obj.width/ 2, obj.height / 2)');
                obj.vframes(:, :, i) = uint8(reshape(frameData(1 + 1.25 * yLength : 1.5 * yLength), obj.width / 2, obj.height / 2)');
            end
            obj.yframes = uint8(obj.yframes);
            obj.uframes = uint8(obj.uframes);
            obj.vframes = uint8(obj.vframes);
        end

        function obj = displayYframe(obj, n)
            imshow(squeeze(obj.yframes(:, :, n)));
        end
    end
end

