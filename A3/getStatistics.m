function stat = getStatistics(param)

stat(1:length(param.QP)) = double(0.0);
heightBlockNum = idivide(uint32(param.height), uint32(param.blockSize), 'ceil');

for i = 1:length(param.QP)

    Lambda = getLambda(param.QP(i));
    encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, ...
        param.blockSize, param.r, param.QP(i), param.I_Period, param.nRefFrames, ...
        param.VBSEnable, param.FMEEnable, param.FastME, Lambda);

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');

    frameStat(1:param.nFrame) = double(0.0);
    for j = 1:param.nFrame
        frameStat(j) = ( ...
            sum(strlength(QTCCoeffs(j,:)), "all") + ...
            sum(strlength(MDiffs(j,:)), "all") + ...
            sum(strlength(splits(j,:)), "all") ...
            ) / heightBlockNum;
    end

    if param.I_Period == 1
        stat(i) = sum(frameStat, "all") / param.nFrame;
    else
        stat(i) = sum(frameStat(2:param.nFrame), "all") / (param.nFrame-1);
    end

end
end