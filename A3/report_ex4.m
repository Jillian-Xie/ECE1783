clc; clear; close all;

QPs = [0 1 2 3 4 5 6 7 8 9 10 11];

load('CIFStatistics.mat', 'CIFStatistics');
load('QCIFStatistics.mat', 'QCIFStatistics');

paramCIF_1 = struct('yuvInputFileName', 'CIF.yuv','nFrame', 21, 'width', 352, 'height', 288, 'blockSize', 16,'r', 16, 'QPs', QPs, 'I_Period', 21, 'nRefFrames', 1, 'VBSEnable', true, 'FMEEnable', true, 'FastME', true, 'visualizeVBS', false, 'visualizeRGB', false, 'visualizeMM', false, 'visualizeNRF', false, 'frameRate', 30, 'parallelMode', 0);

runAndDrawCurves("R-D plot for different RCFlags and dQPLimits", "PSNR", "Bitcount", CIFStatistics, paramCIF_1);

function runAndDrawCurves(fig_title, y_axis, x_axis, statistics, varargin) % varargin: parameters
plotOutputPath = ['Plots' filesep];

legends = strings([nargin-4, 1]);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for i = 1:(nargin-4)
    x = zeros(4, 3);
    y = zeros(4, 3);
    perFrameBitCount = zeros(4, varargin{i}.nFrame);
    frameCount = zeros(4, varargin{i}.nFrame);
    RCFlags = [4];
    dQPLimits = [1,2,3];
    targetBRs = [7200000, 2400000, 1000000];

    for index1 = 1:numel(RCFlags)
        RCFlag = 1;
        legends(1, :) = strcat('RCFlag=',string(RCFlag));
        for index3 = 1:numel(targetBRs)
            targetBR = targetBRs(index3);
            tic;
            reconstructedY = encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, ...
                    varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, ...
                    varargin{i}.r, 6, varargin{i}.I_Period, varargin{i}.nRefFrames, ...
                    varargin{i}.VBSEnable, varargin{i}.FMEEnable, varargin{i}.FastME, ...
                    RCFlag, targetBR, varargin{i}.frameRate, ...
                    varargin{i}.QPs, statistics, varargin{i}.parallelMode, 0);
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
                frameBits = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all") + sum(strlength(QPFrames(j,:)), "all");
                totalBits = totalBits + frameBits;
                if targetBR == 2400000
                    perFrameBitCount(1, j) = frameBits;
                    frameCount(1, j) = j;
                end
            end
            thisPSNR = psnr(YOutput(:, :, 1:varargin{i}.nFrame), YOriginal(:,:,1:varargin{i}.nFrame));

            x(1, index3) = totalBits;
            y(1, index3) = thisPSNR;
        end
    end

    for index1 = 1:numel(RCFlags)
        RCFlag = RCFlags(index1);
        for index2 = 1:numel(dQPLimits)
            dQPLimit = dQPLimits(index2);
            legends((index1-1)*numel(RCFlags) + index2 + 1, :) = strcat('RCFlag=',string(RCFlag), ', dQPLimit=', string(dQPLimit));
            for index3 = 1:numel(targetBRs)
                targetBR = targetBRs(index3);
                tic;
                reconstructedY = encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, ...
                        varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, ...
                        varargin{i}.r, 6, varargin{i}.I_Period, varargin{i}.nRefFrames, ...
                        varargin{i}.VBSEnable, varargin{i}.FMEEnable, varargin{i}.FastME, ...
                        RCFlag, targetBR, varargin{i}.frameRate, ...
                        varargin{i}.QPs, statistics, varargin{i}.parallelMode, dQPLimit);
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
                    frameBits = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all") + sum(strlength(QPFrames(j,:)), "all");
                    totalBits = totalBits + frameBits;
                    if targetBR == 2400000
                        perFrameBitCount((index1-1)*numel(RCFlags) + index2 + 1, j) = frameBits;
                        frameCount((index1-1)*numel(RCFlags) + index2 + 1, j) = j;
                    end
                end
                thisPSNR = psnr(YOutput(:, :, 1:varargin{i}.nFrame), YOriginal(:,:,1:varargin{i}.nFrame));
    
                x((index1-1)*numel(RCFlags) + index2 + 1, index3) = totalBits;
                y((index1-1)*numel(RCFlags) + index2 + 1, index3) = thisPSNR;
            end
        end
    end

    plot(x', y', '-o');
    title(fig_title);
    grid on;
    xlabel(x_axis);
    ylabel(y_axis);

    legend(legends,'Location','best');
    saveas(gcf, fullfile(strcat(plotOutputPath, 'ex4-rd' , '.jpeg')));
    delete(gcf);

    plot(frameCount', perFrameBitCount', '-o');
    title('per-frame bit count when BR=2.4mbps');
    grid on;
    xlabel('Frame');
    ylabel('Bitcount');

    legend(legends,'Location','best');
    saveas(gcf, fullfile(strcat(plotOutputPath, 'ex4-bc' , '.jpeg')));
    delete(gcf);
end

end