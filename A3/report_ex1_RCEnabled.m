clc; clear; close all;

QPs = [1 2 3 4 5 6 7 8 9 10 11];

load('CIFStatistics.mat', 'CIFStatistics');
load('QCIFStatistics.mat', 'QCIFStatistics');

paramCIF_1 = struct('yuvInputFileName', 'CIF.yuv','nFrame', 21,'width', 352,'height', 288,'blockSize', 16,'r', 16,'QPs', QPs,'QP', 4,'I_Period', 1,'nRefFrames', 1,'VBSEnable', true,'FMEEnable', true,'FastME', true,'visualizeVBS', false,'visualizeRGB', false,'visualizeMM', false,'visualizeNRF', false,'RCFlag', 1,'targetBR', 2400000,'frameRate', 30);
paramCIF_4 = struct('yuvInputFileName', 'CIF.yuv','nFrame', 21,'width', 352,'height', 288,'blockSize', 16,'r', 16,'QPs', QPs,'QP', 4,'I_Period', 4,'nRefFrames', 1,'VBSEnable', true,'FMEEnable', true,'FastME', true,'visualizeVBS', false,'visualizeRGB', false,'visualizeMM', false,'visualizeNRF', false,'RCFlag', 1,'targetBR', 2400000,'frameRate', 30);
paramCIF_21 = struct('yuvInputFileName', 'CIF.yuv','nFrame', 21,'width', 352,'height', 288,'blockSize', 16,'r', 16,'QPs', QPs,'I_Period', 21,'QP', 4,'nRefFrames', 1,'VBSEnable', true,'FMEEnable', true,'FastME', true,'visualizeVBS', false,'visualizeRGB', false,'visualizeMM', false,'visualizeNRF', false,'RCFlag', 1,'targetBR', 2400000,'frameRate', 30);
paramQCIF_1 = struct('yuvInputFileName', 'QCIF.yuv','nFrame', 21,'width', 176,'height', 144,'blockSize', 16,'r', 16,'QPs', QPs,'I_Period', 1,'QP', 4,'nRefFrames', 1,'VBSEnable', true,'FMEEnable', true,'FastME', true,'visualizeVBS', false,'visualizeRGB', false,'visualizeMM', false,'visualizeNRF', false,'RCFlag', 1,'targetBR', 960000,'frameRate', 30);
paramQCIF_4 = struct('yuvInputFileName', 'QCIF.yuv','nFrame', 21,'width', 176,'height', 144,'blockSize', 16,'r', 16,'QPs', QPs,'I_Period', 4,'QP', 4,'nRefFrames', 1,'VBSEnable', true,'FMEEnable', true,'FastME', true,'visualizeVBS', false,'visualizeRGB', false,'visualizeMM', false,'visualizeNRF', false,'RCFlag', 1,'targetBR', 960000,'frameRate', 30);
paramQCIF_21 = struct('yuvInputFileName', 'QCIF.yuv','nFrame', 21,'width', 176,'height', 144,'blockSize', 16,'r', 16,'QPs', QPs,'I_Period', 21,'QP', 4,'nRefFrames', 1,'VBSEnable', true,'FMEEnable', true,'FastME', true,'visualizeVBS', false,'visualizeRGB', false,'visualizeMM', false,'visualizeNRF', false,'RCFlag', 1,'targetBR', 960000,'frameRate', 30);

runAndDrawCurves("PSNR vs FrameIndex (CIF.yuv)", "PSNR", "FrameIndex", CIFStatistics, paramCIF_1, paramCIF_4, paramCIF_21);
runAndDrawCurves("PSNR vs FrameIndex (QCIF.yuv)","PSNR", "FrameIndex", QCIFStatistics, paramQCIF_1, paramQCIF_4, paramQCIF_21);

runAndDrawCurves("Bitcount vs FrameIndex (CIF.yuv)", "Bitcount", "FrameIndex", CIFStatistics, paramCIF_1, paramCIF_4, paramCIF_21);
runAndDrawCurves("Bitcount vs FrameIndex (QCIF.yuv)", "Bitcount", "FrameIndex", QCIFStatistics, paramQCIF_1, paramQCIF_4, paramQCIF_21);

function runAndDrawCurves(fig_title, y_axis, x_axis, statistics, varargin) % varargin: parameters
plotOutputPath = ['Plots' filesep];

y(1:varargin{1}.nFrame, 1:(nargin-4)) = double(0.0);
x(1:varargin{1}.nFrame, 1:(nargin-4)) = double(0.0);

legends = strings([nargin-4, 1]);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for i = 1:(nargin-4)
    legends(i, :) = "IPeriod = " + int2str(varargin{i}.I_Period);
    reconstructedY = encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, ...
        varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, ...
        varargin{i}.r, varargin{i}.QP, varargin{i}.I_Period, varargin{i}.nRefFrames, ...
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

    im(:,:,1)=YOutput(:,:,4);
    im(:,:,2)=YOutput(:,:,4);
    im(:,:,3)=YOutput(:,:,4);
    imwrite(uint8(im),[plotOutputPath, sprintf('%d',varargin{i}.targetBR), '_', sprintf('%d',varargin{i}.I_Period),'.png']);

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
saveas(gcf, fullfile(plotOutputPath + x_axis + '_' + y_axis + '_' + int2str(varargin{1}.targetBR) + '.jpeg'));

end