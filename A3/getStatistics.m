function stat = getStatistics(param)

% config info
yuvInputFileName = 'CIF.yuv';
nFrame = 21;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QPs = [0 1 2 3 4 5 6 7 8 9 10 11];
QP = 5;
I_Period = 10;

nRefFrames = 1;
VBSEnable = true;
FMEEnable = true;
FastME = true;

RCFlag = 4;
targetBR = 1140480; % bps
frameRate = 30;
parallelMode = 0;
dQPLimit = 2;
% parpool(2);

visualizeVBS = VBSEnable && false;
visualizeRGB = true;
visualizeMM = false;
visualizeNRF= false;
statistics = [];

stat(1:length(param.QPs)) = double(0.0);
heightBlockNum = idivide(uint32(param.height), uint32(param.blockSize), 'ceil');

for i = 1:length(param.QPs)

    encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, ...
        param.blockSize, param.r, param.QPs(i), param.I_Period, param.nRefFrames, ...
        param.VBSEnable, param.FMEEnable, param.FastME, 0, targetBR, frameRate, ...
        QPs, statistics, parallelMode, dQPLimit);

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