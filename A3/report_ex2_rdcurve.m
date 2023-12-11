clc; clear; close all;

QPs = [0 1 2 3 4 5 6 7 8 9 10 11];

load('CIFStatistics.mat', 'CIFStatistics');
load('QCIFStatistics.mat', 'QCIFStatistics');

paramCIF_1 = struct('yuvInputFileName', 'CIF.yuv','nFrame', 21, 'width', 352, 'height', 288, 'blockSize', 16,'r', 16, 'QPs', QPs, 'I_Period', 4, 'nRefFrames', 1, 'VBSEnable', true, 'FMEEnable', true, 'FastME', true, 'visualizeVBS', false, 'visualizeRGB', false, 'visualizeMM', false, 'visualizeNRF', false, 'frameRate', 30);

runAndDrawCurves("R-D plot for different RCFlags", "PSNR", "Bitcount", CIFStatistics, paramCIF_1);

function runAndDrawCurves(fig_title, y_axis, x_axis, statistics, varargin) % varargin: parameters
plotOutputPath = ['Plots' filesep];

legends = strings([nargin-4, 1]);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for i = 1:(nargin-4)
    x = zeros(4, 3);
    y = zeros(4, 3);
    QPs = [3,6,9];
    for index = 1:numel(QPs)
        QP = QPs(index);
        legends(1, :) = 'RCFlag=0';
        RCFlag = 0;
        targetBR = 0;
        tic;
        reconstructedY = encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, ...
                varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, ...
                varargin{i}.r, QP, varargin{i}.I_Period, varargin{i}.nRefFrames, ...
                varargin{i}.VBSEnable, varargin{i}.FMEEnable, varargin{i}.FastME, ...
                RCFlag, targetBR, varargin{i}.frameRate, ...
                varargin{i}.QPs, statistics, 0, 2);
        toc;
            
        load('QTCCoeffs.mat', 'QTCCoeffs');
        load('MDiffs.mat', 'MDiffs');
        load('splits.mat', 'splits');
        load('QPFrames.mat', 'QPFrames');

        tic;
        decoder(varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, ...
            varargin{i}.blockSize, varargin{i}.VBSEnable, ...
            varargin{i}.FMEEnable, QTCCoeffs, MDiffs, splits, QPFrames, false, ...
            false, false, false, reconstructedY);
        toc;
        
        YOutput = importYOnly(['DecoderOutput' filesep 'outputYUV.yuv'], varargin{i}.width, varargin{i}.height ,varargin{i}.nFrame);
        [YOriginal, ~, ~] = importYUV(varargin{i}.yuvInputFileName, varargin{i}.width, varargin{i}.height, varargin{i}.nFrame);
        
        totalBits = 0;
        for j=1:varargin{i}.nFrame
            totalBits = totalBits + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all") + sum(strlength(QPFrames(j,:)), "all");
        end
        thisPSNR = psnr(YOutput(:, :, 1:varargin{i}.nFrame), YOriginal(:,:,1:varargin{i}.nFrame));
        
        x(1, index) = totalBits;
        y(1, index) = thisPSNR;
    end
    
    for RCFlag = [1,2,3]
        targetBRs = [7200000, 2400000, 360000];
        legends(RCFlag+1, :) = strcat('RCFlag=',string(RCFlag));
        for index = 1:numel(targetBRs) % 7.2mbps, 2.4mbps, 360kbps
            targetBR = targetBRs(index);
            tic;
            reconstructedY = encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, ...
                    varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, ...
                    varargin{i}.r, QP, varargin{i}.I_Period, varargin{i}.nRefFrames, ...
                    varargin{i}.VBSEnable, varargin{i}.FMEEnable, varargin{i}.FastME, ...
                    RCFlag, targetBR, varargin{i}.frameRate, ...
                    varargin{i}.QPs, statistics);
            toc;

            load('QTCCoeffs.mat', 'QTCCoeffs');
            load('MDiffs.mat', 'MDiffs');
            load('splits.mat', 'splits');
            load('QPFrames.mat', 'QPFrames');

            tic;
            decoder(varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, ...
                varargin{i}.blockSize, varargin{i}.VBSEnable, ...
                varargin{i}.FMEEnable, QTCCoeffs, MDiffs, splits, QPFrames, false, ...
                false, false, false, reconstructedY);
            toc;

            YOutput = importYOnly(['DecoderOutput' filesep 'outputYUV.yuv'], varargin{i}.width, varargin{i}.height ,varargin{i}.nFrame);
            [YOriginal, ~, ~] = importYUV(varargin{i}.yuvInputFileName, varargin{i}.width, varargin{i}.height, varargin{i}.nFrame);

            totalBits = 0;
            for j=1:varargin{i}.nFrame
                totalBits = totalBits + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all") + sum(strlength(QPFrames(j,:)), "all");
            end
            thisPSNR = psnr(YOutput(:, :, 1:varargin{i}.nFrame), YOriginal(:,:,1:varargin{i}.nFrame));

            x(RCFlag+1, index) = totalBits;
            y(RCFlag+1, index) = thisPSNR;
        end
    end
    plot(x', y', '-o');
    title(fig_title);
    grid on;
    xlabel(x_axis);
    ylabel(y_axis);

    legend(legends,'Location','best');
    saveas(gcf, fullfile(strcat(plotOutputPath, 'ex2-rd' , '.jpeg')));
end



end