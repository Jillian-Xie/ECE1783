function codec(isEncode, filepath, options)
    arguments
        isEncode (1,1) int32
        filepath (1,:) char
        options.width (1,1) int32
        options.height (1,1) int32
        options.nframes (1,1) double
        % i: blockSize
        options.i (1,1) int32 = 4
        % r: searchRange
        options.r (1,1) int32 = 1
        % n: approximated index
        options.n (1,1) double = 2
        % QP: quatization index
        options.QP (1,1) double = -1
        % I_Period
        options.I_Period (1,1) double = -1
        % using Differential Encoding
        options.isDifferential (1,1) int8 = 0
        % using Entropy
        options.isEntropy (1, 1) int8 = 0
        % reference frame number
        options.nRefFrames (1, 1) int8 = 0
        % VBSEnable
        options.VBSEnable (1, 1) int8 = 0
        % FMEEnable
        options.FMEEnable (1, 1) int8 = 0
        % FastME
        options.FastME (1, 1) int8 = 0
    end

    % isEncode: 1 - encode, 0 - decode
    if isEncode == 1
        encoder(filepath, options.width, options.height, ...
            options.nframes, options.i, options.r, options.n,...
            options.QP, options.I_Period, options.isDifferential,...
            options.isEntropy, options.nRefFrames, options.VBSEnable, ...
            options.FMEEnable, options.FastME).encode();
    else
        decoder(filepath).decode();
    end
end