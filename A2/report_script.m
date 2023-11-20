clc; clear; close all; 

plotOutputPath = strcat('Plots', filesep);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

% config info
yuvInputFileName = 'foreman420_cif.yuv';
nFrame = 10;
width  = uint32(352);
height = uint32(288);

% sweepLambda(yuvInputFileName, nFrame, width, height, plotOutputPath);
part2And3(yuvInputFileName, nFrame, width, height, plotOutputPath);

function part2And3(yuvInputFileName, nFrame, width, height, plotOutputPath)
    blockSize = 16;
    r = 4;
    QPs = [1,4,7];
%     QPs = double(1:int8(log2(blockSize) + 7))
    I_Period = 8;

    nRefFrames = 1;
    VBSEnable = true;
    FMEEnable = false;
    FastME = false;

    visualizeVBS = VBSEnable && true;
    
    totalBits = [];
    splitPercentages = [];

    for QP = QPs
        Lambda = getLambda(QP);
        % encoder
        tic
        reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, Lambda);
        toc

        load('QTCCoeffs.mat', 'QTCCoeffs');
        load('MDiffs.mat', 'MDiffs');
        load('splits.mat', 'splits');
        
        totalBitsFrame = 0;
        for i = 1:nFrame
            totalBitsFrame = totalBitsFrame + sum(strlength(QTCCoeffs(i,:)), "all") + sum(strlength(MDiffs(i,:)), "all") + sum(strlength(splits(i,:)), "all");
        end
        
        totalBits = [totalBits, totalBitsFrame];

        % decoder
        tic
        splitPercentage = decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, false, false, false, reconstructedY);
        toc
        
        splitPercentages = [splitPercentages, splitPercentage];
    end

    plotAgainstFrame(QPs, splitPercentages, 'QP', 'split percentages', 'split percentages vs. QP', 'q2.jpeg', plotOutputPath);
    plotAgainstFrame(totalBits, splitPercentages, 'total bits', 'split percentages', 'split percentages vs. total bits', 'q3.jpeg', plotOutputPath);
end

function plotAgainstFrame(x_frame, yVals, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath)
    figure
    for i = 1:size(yVals, 1)
        plot(x_frame, yVals(i, :), '-o');
        hold on
    end
    xlabel(xaxisLabel);
    ylabel(yaxisLabel);
    grid on;
    hold off
    
    title(titleStr);
    saveas(gcf, fullfile(strcat(plotOutputPath, filenameStr)));
    delete(gcf);
end

function sweepLambda(yuvInputFileName, nFrame, width, height, plotOutputPath)
    blockSize = 16;
    r = 4;
%     QPs = [1,4,7,10];
    QPs = [2];
    I_Period = 8;

    nRefFrames = 1;
    VBSEnable = false;
    FMEEnable = false;
    FastME = false;

    visualizeVBS = VBSEnable && true;
    
    for QP = QPs
        VBSEnable = true;

        % https://ieeexplore.ieee.org/document/1626308
        if QP == 1
            Lambdas = [0, logspace(log10(0.01), log10(0.8), 7)]
        elseif QP == 2
            Lambdas = [0, logspace(log10(0.01), log10(1), 7)]
        elseif QP == 4
            Lambdas = [0, logspace(log10(0.01), log10(1.5), 7)]
        elseif QP == 7
            Lambdas = [0, logspace(log10(1), log10(15), 7)]
        elseif QP == 10
            Lambdas = [0, logspace(log10(3), log10(80), 7)]
        end

        totalBits = [];
        PSNRs = [];

        for Lambda = Lambdas
            % encoder
            tic
            reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, Lambda);
            toc

            load('QTCCoeffs.mat', 'QTCCoeffs');
            load('MDiffs.mat', 'MDiffs');
            load('splits.mat', 'splits');

            totalBitsFrame = 0;
            for i = 1:nFrame
                totalBitsFrame = totalBitsFrame + sum(strlength(QTCCoeffs(i,:)), "all") + sum(strlength(MDiffs(i,:)), "all") + sum(strlength(splits(i,:)), "all");
            end

            totalBits = [totalBits, totalBitsFrame];

            % decoder
            tic
            decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, false, false, false, reconstructedY);
            toc

            YOutput = importYOnly(['DecoderOutput' filesep 'outputYUV.yuv'], width, height ,nFrame);
            [YOriginal, U, V] = importYUV(yuvInputFileName, width, height, nFrame);  

            avg_psnr = 0;
            for i = 1:nFrame
                avg_psnr = avg_psnr + psnr(YOutput(:,:,i), YOriginal(:,:,i)) / nFrame;
            end
%             avg_psnr = psnr(YOutput, YOriginal);

            PSNRs = [PSNRs, avg_psnr];

            disp(strcat('Lambda=', string(Lambda), ', PSNR=', string(avg_psnr), ', total Bits=', string(totalBitsFrame), ', PSNR/totalBits=', string(avg_psnr/totalBitsFrame)));
        end

        VBSEnable = false;
        % encoder
        tic
        reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, 0);
        toc

        load('QTCCoeffs.mat', 'QTCCoeffs');
        load('MDiffs.mat', 'MDiffs');
        load('splits.mat', 'splits');

        totalBitsFrame = 0;
        for i = 1:nFrame
            totalBitsFrame = totalBitsFrame + sum(strlength(QTCCoeffs(i,:)), "all") + sum(strlength(MDiffs(i,:)), "all") + sum(strlength(splits(i,:)), "all");
        end
        totalBits = [totalBits, totalBitsFrame];

        % decoder
        tic
        decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, false, false, false, reconstructedY);
        toc

        YOutput = importYOnly(['DecoderOutput' filesep 'outputYUV.yuv'], width, height ,nFrame);
        [YOriginal, U, V] = importYUV(yuvInputFileName, width, height, nFrame);

        avg_psnr = 0;
        for i = 1:nFrame
            avg_psnr = avg_psnr + psnr(YOutput(:,:,i), YOriginal(:,:,i)) / nFrame;
        end
%         avg_psnr = psnr(YOutput, YOriginal);
        PSNRs = [PSNRs, avg_psnr];

        disp(strcat('VBS disabled, PSNR=', string(avg_psnr), ', total Bits=', string(totalBitsFrame)));

        plotAgainstFrame(totalBits, PSNRs, 'totalBits', 'PSNR', strcat('R-D plot when QP=',string(QP), ' varying Lambda'), strcat('qp',string(QP),'.jpeg'), plotOutputPath);
    end
end
