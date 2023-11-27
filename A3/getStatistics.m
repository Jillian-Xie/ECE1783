function stat = getStatistics(param)

stat(1:length(param.QPs)) = double(0.0);
heightBlockNum = idivide(uint32(param.height), uint32(param.blockSize), 'ceil');

for i = 1:length(param.QPs)

    encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, ...
        param.blockSize, param.r, param.QPs(i), param.I_Period, param.nRefFrames, ...
        param.VBSEnable, param.FMEEnable, param.FastME, false);

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');
    load('QPFrames.mat', 'QPFrames');

    frameStat(1:param.nFrame) = double(0.0);
    for j = 1:param.nFrame
        frameStat(j) = ( ...
            sum(strlength(QTCCoeffs(j,:)), "all") + ...
            sum(strlength(MDiffs(j,:)), "all") + ...
            sum(strlength(splits(j,:)), "all") + ...
            sum(strlength(QPFrames(j,:)), "all") ...
            ) / heightBlockNum;
    end

    if param.I_Period == 1
        stat(i) = sum(frameStat, "all") / param.nFrame;
    else
        stat(i) = sum(frameStat(2:param.nFrame), "all") / (param.nFrame-1);
    end

end
end