clc; clear; close all;

QPs = [0 1 2 3 4 5 6 7 8 9 10 11];

load('CIFStatistics.mat', 'CIFStatistics');
load('QCIFStatistics.mat', 'QCIFStatistics');

paramCIF_1 = struct('yuvInputFileName', 'CIF.yuv','nFrame', 21, 'width', 352, 'height', 288, 'blockSize', 16,'r', 16, 'QPs', QPs, 'I_Period', 1, 'nRefFrames', 1, 'VBSEnable', true, 'FMEEnable', true, 'FastME', true, 'visualizeVBS', false, 'visualizeRGB', false, 'visualizeMM', false, 'visualizeNRF', false, 'RCFlag', 0, 'targetBR', 2400000, 'frameRate', 30);
paramQCIF_1 = struct('yuvInputFileName', 'QCIF.yuv','nFrame', 21, 'width', 176, 'height', 144, 'blockSize', 16,'r', 16, 'QPs', QPs, 'I_Period', 1, 'nRefFrames', 1, 'VBSEnable', true, 'FMEEnable', true, 'FastME', true, 'visualizeVBS', false, 'visualizeRGB', false, 'visualizeMM', false, 'visualizeNRF', false, 'RCFlag', 0, 'targetBR', 960000, 'frameRate', 30);

runAndDrawCurves("Average Per-Block Bitcount vs QP for I frames", "Bitcount", "QP", CIFStatistics, paramCIF_1, paramQCIF_1);

function runAndDrawCurves(fig_title, y_axis, x_axis, statistics, varargin) % varargin: parameters
plotOutputPath = ['Plots' filesep];

y(1:size(varargin{1}.QPs, 2), 1:(nargin-4)) = double(0.0);
x(1:size(varargin{1}.QPs, 2), 1:(nargin-4)) = double(0.0);

legends = strings([nargin-4, 1]);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for i = 1:(nargin-4)
    legends(i, :) = varargin{i}.yuvInputFileName;
    widthBlockNum = idivide(uint32(varargin{i}.width), uint32(varargin{i}.blockSize), 'ceil');
    heightBlockNum = idivide(uint32(varargin{i}.height), uint32(varargin{i}.blockSize), 'ceil');
    
    for k = 1:size(varargin{1}.QPs, 2)
        QP = varargin{1}.QPs(1, k);
        reconstructedY = encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, ...
            varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, ...
            varargin{i}.r, QP, varargin{i}.I_Period, varargin{i}.nRefFrames, ...
            varargin{i}.VBSEnable, varargin{i}.FMEEnable, varargin{i}.FastME, ...
            varargin{i}.RCFlag, varargin{i}.targetBR, varargin{i}.frameRate, ...
            varargin{i}.QPs, statistics, 0, 2);

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
        
        totalBits = 0;
        for j=1:varargin{i}.nFrame
            totalBits = totalBits + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all") + sum(strlength(QPFrames(j,:)), "all");
        end
        perBlockAvg = totalBits / double(varargin{i}.nFrame * widthBlockNum * heightBlockNum);
        y(k, i) = perBlockAvg;
        x(k, i) = QP;
    end
end
y
plot(x, y, '-o');
title(fig_title);
xlabel(x_axis);
ylabel(y_axis);

legend(legends,'Location','best');
saveas(gcf, fullfile(strcat(plotOutputPath, 'per_block_bitcount_for_I_frame' , '.jpeg')));

end