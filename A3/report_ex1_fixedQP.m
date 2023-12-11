clc; clear; close all;

QPs = [0 1 2 3 4 5 6 7 8 9 10 11];
load('CIFStatistics.mat', 'CIFStatistics');

param = struct( ...
    'yuvInputFileName', 'CIF.yuv', ...
    'nFrame', 21, ...
    'width', 352, ...
    'height', 288, ...
    'blockSize', 16, ...
    'r', 16, ...
    'QPs', QPs, ...
    'QP', 4, ...
    'I_Period', 21, ...
    'nRefFrames', 1, ...
    'VBSEnable', true, ...
    'FMEEnable', true, ...
    'FastME', true, ...
    'visualizeVBS', false, ...
    'visualizeRGB', false, ...
    'visualizeMM', false, ...
    'visualizeNRF', false, ...
    'RCFlag', 1, ...
    'targetBR', 2400000, ...
    'frameRate', 30 ...
    );

% QP = findClosestQP(param, CIFStatistics);

QP = 4;

param_1 = param;
param_1.QP = QP;
param_1.RCFlag = 0;

runAndDrawCurves("PSNR vs FrameIndex (CIF.yuv IPeriod=21)", "PSNR", "FrameIndex", param, param_1);
runAndDrawCurves("Bitcount vs FrameIndex (CIF.yuv IPeriod=21)", "Bitcount", "FrameIndex", param, param_1);

function QP = findClosestQP(param, statistics)

    encoder(param.yuvInputFileName, param.nFrame, ...
    param.width, param.height, param.blockSize, ...
    param.r, param.QP, param.I_Period, param.nRefFrames, ...
    param.VBSEnable, param.FMEEnable, param.FastME, ...
    param.RCFlag, param.targetBR, param.frameRate, ...
    param.QPs, statistics);

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');
    load('QPFrames.mat', 'QPFrames');

    targetAverageFrameBitcount = getAverageBitcount(param.nFrame, QTCCoeffs, MDiffs, splits, QPFrames);

    QPLeft = 0;
    QPRight = 11;

    while (1)
        if QPLeft >= QPRight || QPRight == QPLeft+1
            break;
        end
        encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, ...
            param.blockSize, param.r, int32(floor(((QPLeft+QPRight)/2))), param.I_Period, param.nRefFrames, ...
            param.VBSEnable, param.FMEEnable, param.FastME, 0);

        load('QTCCoeffs.mat', 'QTCCoeffs');
        load('MDiffs.mat', 'MDiffs');
        load('splits.mat', 'splits');
        load('QPFrames.mat', 'QPFrames');

        averageFrameBitcount = getAverageBitcount(param.nFrame, QTCCoeffs, MDiffs, splits, QPFrames);

        if averageFrameBitcount > targetAverageFrameBitcount
            QPLeft = int32(floor(((QPLeft+QPRight)/2)));
        elseif averageFrameBitcount < targetAverageFrameBitcount
            QPRight = int32(floor(((QPLeft+QPRight)/2)));
        else
            QPLeft = int32(floor(((QPLeft+QPRight)/2)));
            QPRight = int32(floor(((QPLeft+QPRight)/2)));
            break;
        end

    end
    
    if QPLeft == QPRight
        QP = int32(floor(((QPLeft+QPRight)/2)));
    else
        encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, ...
            param.blockSize, param.r, QPLeft, param.I_Period, param.nRefFrames, ...
            param.VBSEnable, param.FMEEnable, param.FastME, 0);

        load('QTCCoeffs.mat', 'QTCCoeffs');
        load('MDiffs.mat', 'MDiffs');
        load('splits.mat', 'splits');
        load('QPFrames.mat', 'QPFrames');

        leftAverageFrameBitcount = getAverageBitcount(param.nFrame, QTCCoeffs, MDiffs, splits, QPFrames);

        encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, ...
            param.blockSize, param.r, QPRight, param.I_Period, param.nRefFrames, ...
            param.VBSEnable, param.FMEEnable, param.FastME, 0);

        load('QTCCoeffs.mat', 'QTCCoeffs');
        load('MDiffs.mat', 'MDiffs');
        load('splits.mat', 'splits');
        load('QPFrames.mat', 'QPFrames');

        rightAverageFrameBitcount = getAverageBitcount(param.nFrame, QTCCoeffs, MDiffs, splits, QPFrames);

        if abs(rightAverageFrameBitcount-targetAverageFrameBitcount) > abs(leftAverageFrameBitcount-targetAverageFrameBitcount)
            QP = QPLeft;
        else
            QP = QPRight;
        end
    end

end

function averageBitcount = getAverageBitcount(nFrames, QTCCoeffs, MDiffs, splits, QPFrames)
    averageBitcount = double(0.0);    
    for i=1:nFrames
    averageBitcount = averageBitcount + (( ...
        sum(strlength(QTCCoeffs(i,:)), "all") + ...
        sum(strlength(MDiffs(i,:)), "all") + ...
        sum(strlength(splits(i,:)), "all") + ...
        sum(strlength(QPFrames(i,:)), "all")) / nFrames);
    end
    averageBitcount = int32(averageBitcount);
end

function runAndDrawCurves(fig_title, y_axis, x_axis, varargin) % varargin: parameters
plotOutputPath = ['Plots' filesep];
load('CIFStatistics.mat', 'CIFStatistics');

y(1:varargin{1}.nFrame, 1:(nargin-3)) = double(0.0);
x(1:varargin{1}.nFrame, 1:(nargin-3)) = double(0.0);

legends = strings([nargin-3, 1]);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for i = 1:(nargin-3)
    legends(i, :) = "RCFlag = " + int2str(varargin{i}.RCFlag);
    reconstructedY = encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, ...
        varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, ...
        varargin{i}.r, varargin{i}.QP, varargin{i}.I_Period, varargin{i}.nRefFrames, ...
        varargin{i}.VBSEnable, varargin{i}.FMEEnable, varargin{i}.FastME, ...
        varargin{i}.RCFlag, varargin{i}.targetBR, varargin{i}.frameRate, varargin{i}.QPs, CIFStatistics, 0, 2);

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');
    load('QPFrames.mat', 'QPFrames');

    decoder(varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, ...
        varargin{i}.blockSize, varargin{i}.VBSEnable, ...
        varargin{i}.FMEEnable, QTCCoeffs, MDiffs, splits, QPFrames, false, ...
        false, false, false, reconstructedY);

    YOutput = importYOnly(['DecoderOutput' filesep 'outputYUV.yuv'], varargin{i}.width, varargin{i}.height ,varargin{i}.nFrame);
    [YOriginal, ~, ~] = importYUV(varargin{i}.yuvInputFileName, varargin{i}.width, varargin{i}.height, varargin{i}.nFrame);
    
    for j=1:varargin{i}.nFrame
        if (y_axis == "PSNR")
            y(j, i) = psnr(YOutput(:, :, j), YOriginal(:,:,j));
        elseif (y_axis == "Bitcount")
            y(j, i) = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all") + sum(strlength(QPFrames(j,:)), "all");
        end

        if (x_axis == "FrameIndex")
            x(j, i) = j;
        elseif (x_axis == "Bitcount")
            if j == 1
                x(j, i) = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all") + sum(strlength(QPFrames(j,:)), "all");
            else
                x(j, i) = x(j - 1, i) + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all") + sum(strlength(QPFrames(j,:)), "all");
            end
        end
    end
end
plot(x, y, '-o');
title(fig_title);
xlabel(x_axis);
if y_axis == "Bitcount"
    ylabel(y_axis + "/Frame");
else
    ylabel(y_axis);
end

legend(legends,'Location','southwest');
saveas(gcf, fullfile(plotOutputPath + x_axis + '_' + y_axis + '_' + "fixedQP" + '.jpeg'));

end