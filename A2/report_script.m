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

part2And3(yuvInputFileName, nFrame, width, height, plotOutputPath);

function part2And3(yuvInputFileName, nFrame, width, height, plotOutputPath)
    blockSize = 16;
    r = 4;
    QPs = double(1:int8(log2(blockSize) + 7));
    I_Period = 8;

    nRefFrames = 1;
    VBSEnable = true;
    FMEEnable = false;
    FastME = false;

    visualizeVBS = VBSEnable && true;
    
    totalBits = [];
    splitPercentages = [];

    for QP = QPs
        % encoder
        tic
        reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME);
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
        splitPercentage = decoder(nFrame, width, height, blockSize, QP, I_Period, VBSEnable, FMEEnable, FastME, QTCCoeffs, MDiffs, splits, visualizeVBS, reconstructedY);
        toc
        
        splitPercentages = [splitPercentages, splitPercentage];
    end

    plotAgainstFrame(QPs, splitPercentages, 'QP', 'split percentages', 'split percentages vs. QP', 'q2.jpeg', plotOutputPath);
    plotAgainstFrame(totalBits, splitPercentages, 'total bits', 'split percentages', 'split percentages vs. total bits', 'q3.jpeg', plotOutputPath);
end

function plotAgainstFrame(x_frame, yVals, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath)
    figure
    for i = 1:size(yVals, 1)
        plot(x_frame, yVals(i, :));
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
