clc; clear; close all; 

yuvInputFileName = 'foreman420_cif.yuv';
width  = uint32(352);
height = uint32(288);
nFrame = uint32(10);
x_frame = [1:nFrame];

yuvInputFileNameSeparator = split(yuvInputFileName, '.');
plotOutputPath = strcat('ex3_', yuvInputFileNameSeparator{1,1}, '_Plots', filesep);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

varyBlockSizes(yuvInputFileName, width, height, nFrame, x_frame, plotOutputPath);
% varyN(yuvInputFileName, width, height, nFrame, x_frame, plotOutputPath);
varyR(yuvInputFileName, width, height, nFrame, x_frame, plotOutputPath);
% plotImplementationNotes(yuvInputFileName, width, height, nFrame);

generateOutputFile(yuvInputFileName, nFrame, width, height, 8, 4, 3);


function plotImplementationNotes(yuvInputFileName, width, height, nFrame)
    r = 4;
    n = 3;
    blockSizes = [2, 8, 64];
    for i = 1:size(blockSizes, 2)
        blockSize = blockSizes(1, i);
        ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
    end
end

function varyBlockSizes(yuvInputFileName, width, height, nFrame, x_frame, plotOutputPath)
    r = 4;
    n = 3;
    blockSizes = [2, 8, 64];
    PSNRs = zeros(size(blockSizes, 2), nFrame);
    MAEs = zeros(size(blockSizes, 2), nFrame);
    legends = strings(1, size(blockSizes, 2));
    disp('varying i');
    for i = 1:size(blockSizes, 2)
        blockSize = blockSizes(1, i);
        tic;
        [Y, reconstructedYFrame, avgMAE, residualMagnitude] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
        encodingTime = toc;
        disp(strcat('i=', num2str(blockSize), ', residualMagnitude is:'))
        disp(residualMagnitude)
        disp(strcat('encoding time is:'))
        disp(encodingTime)
        for j = 1:nFrame
            PSNRFrame = psnr(reconstructedYFrame(:,:,j), Y(:,:,j));
            PSNRs(i, j) = PSNRFrame;
        end
        MAEs(i, :) = avgMAE;
        legends(1, i) = strcat('i=', num2str(blockSizes(1, i)));
    end
    
    xaxisLabel = 'Frame';
    yaxisLabel = 'PSNR';
    titleStr = strcat('PSNR when r=', num2str(r), ', n=', num2str(n), ' and varying i');
    filenameStr = strcat('psnr_r_', num2str(r), '_n_', num2str(n), '_varying_i.jpeg');
    plotAgainstFrame(x_frame, PSNRs, legends, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath);
    
    
    xaxisLabel = 'Frame';
    yaxisLabel = 'MAE';
    titleStr = strcat('MAE when r=', num2str(r), ', n=', num2str(n), ' and varying i');
    filenameStr = strcat('mae_r_', num2str(r), '_n_', num2str(n), '_varying_i.jpeg');
    plotAgainstFrame(x_frame, MAEs, legends, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath);
end

function varyN(yuvInputFileName, width, height, nFrame, x_frame, plotOutputPath)
    r = 4;
    blockSize = 8;
    ns = [1, 2, 3];
    PSNRs = zeros(size(ns, 2), nFrame);
    MAEs = zeros(size(ns, 2), nFrame);
    legends = strings(1, size(ns, 2));
    for i = 1:size(ns, 2)
        n = ns(1, i);
        [Y, reconstructedYFrame, avgMAE, residualMagnitude] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
        for j = 1:nFrame
            PSNRFrame = psnr(reconstructedYFrame(:,:,j), Y(:,:,j));
            PSNRs(i, j) = PSNRFrame;
        end
        MAEs(i, :) = avgMAE;
        legends(1, i) = strcat('n=', num2str(ns(1, i)));
    end
    
    xaxisLabel = 'Frame';
    yaxisLabel = 'PSNR';
    titleStr = strcat('PSNR when r=', num2str(r), ', i=', num2str(blockSize), ' and varying n');
    filenameStr = strcat('psnr_r_', num2str(r), '_i_', num2str(blockSize), '_varying_n.jpeg');
    plotAgainstFrame(x_frame, PSNRs, legends, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath);
    
    
    xaxisLabel = 'Frame';
    yaxisLabel = 'MAE';
    titleStr = strcat('MAE when r=', num2str(r), ', i=', num2str(blockSize), ' and varying n');
    filenameStr = strcat('mae_r_', num2str(r), '_i_', num2str(blockSize), '_varying_n.jpeg');
    plotAgainstFrame(x_frame, MAEs, legends, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath);
end

function varyR(yuvInputFileName, width, height, nFrame, x_frame, plotOutputPath)
    n = 3;
    blockSize = 8;
    rs = [1, 4, 8];
    PSNRs = zeros(size(rs, 2), nFrame);
    MAEs = zeros(size(rs, 2), nFrame);
    legends = strings(1, size(rs, 2));
    disp('varying r');
    for i = 1:size(rs, 2)
        r = rs(1, i);
        tic;
        [Y, reconstructedYFrame, avgMAE, residualMagnitude] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
        encodingTime = toc;
        disp(strcat('r=', num2str(r), ', residualMagnitude is:'))
        disp(residualMagnitude)
        disp(strcat('encoding time is:'))
        disp(encodingTime)
        for j = 1:nFrame
            PSNRFrame = psnr(reconstructedYFrame(:,:,j), Y(:,:,j));
            PSNRs(i, j) = PSNRFrame;
        end
        MAEs(i, :) = avgMAE;
        legends(1, i) = strcat('r=', num2str(rs(1, i)));
    end
    
    xaxisLabel = 'Frame';
    yaxisLabel = 'PSNR';
    titleStr = strcat('PSNR when i=', num2str(blockSize), ', n=', num2str(n), ' and varying r');
    filenameStr = strcat('psnr_i_', num2str(blockSize), '_n_', num2str(n), '_varying_r.jpeg');
    plotAgainstFrame(x_frame, PSNRs, legends, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath);
    
    
    xaxisLabel = 'Frame';
    yaxisLabel = 'MAE';
    titleStr = strcat('MAE when i=', num2str(blockSize), ', n=', num2str(n), ' and varying r');
    filenameStr = strcat('mae_i_', num2str(blockSize), '_n_', num2str(n), '_varying_r.jpeg');
    plotAgainstFrame(x_frame, MAEs, legends, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath);
end


function generateOutputFile(yuvInputFileName, nFrame, width, height, blockSize, r, n)
    [Y, reconstructedFrame, avgMAE] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
    reconstructedY(1:width,1:height,1:nFrame) = uint8(0);
    yuvInputFileNameSeparator = split(yuvInputFileName, '.');
    widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
    heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

    MV_X(1:heightBlockNum,1:widthBlockNum,1:nFrame) = int32(0);
    MV_Y(1:heightBlockNum,1:widthBlockNum,1:nFrame) = int32(0);

    for i=1:nFrame
        reconstructedY(:,:,i) = reconstructedFrame(1:height,1:width,i)';
    end
    yuvOutputFileName = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_encoderReconstructionOutput', filesep, yuvInputFileNameSeparator{1,1}, num2str(nFrame), '.yuv');
    fid = createOrClearFile(yuvOutputFileName);
    for i=1:nFrame
    fwrite(fid,uint8(reconstructedY(:,:,i)),'uchar');
    end
    fclose(fid);

    MVInputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_MVOutput', filesep);
    for i=1:nFrame
        MVFilePath = [MVInputPath, sprintf('%04d',i), '.mat'];
        load(MVFilePath, "MVCell");
        for widthBlockIndex = 1:widthBlockNum
            for heightBlockIndex = 1:heightBlockNum
                MV_X(heightBlockIndex,widthBlockIndex,i) = MVCell{heightBlockIndex,widthBlockIndex}(1);
                MV_Y(heightBlockIndex,widthBlockIndex,i) = MVCell{heightBlockIndex,widthBlockIndex}(2);
            end
        end
    end
    MVOutputFileName = strcat(MVInputPath, filesep, "MVTextFile.txt");
    MVResult = [MV_X;MV_Y];
    writematrix(MVResult, MVOutputFileName);
end

function plotAgainstFrame(x_frame, yVals, legends, xaxisLabel, yaxisLabel, titleStr, filenameStr, plotOutputPath)
    figure
    for i = 1:size(yVals, 1)
        plot(x_frame, yVals(i, :),'DisplayName',legends(1, i));
        hold on
    end
    legend('location', 'best');
    xlabel(xaxisLabel);
    ylabel(yaxisLabel);
    grid on;
    hold off
    
    title(titleStr);
    saveas(gcf, fullfile(strcat(plotOutputPath, filenameStr)));
    delete(gcf);
end