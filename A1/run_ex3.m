clc; clear; close all; 

yuvInputFileName = 'foreman420_cif.yuv';
width  = uint32(352);
height = uint32(288);
nFrame = uint32(10);
x_frame = [1:nFrame];

% varyBlockSizes(yuvInputFileName, width, height, nFrame, x_frame);
% varyN(yuvInputFileName, width, height, nFrame, x_frame);
varyR(yuvInputFileName, width, height, nFrame, x_frame);

function varyBlockSizes(yuvInputFileName, width, height, nFrame, x_frame)
    r = 4;
    n = 3;
    blockSizes = [2, 8, 64];
    PSNRs = zeros(size(blockSizes, 2), nFrame);
    MAEs = zeros(size(blockSizes, 2), nFrame);
    for i = 1:size(blockSizes, 2)
        blockSize = blockSizes(1, i);
        [Y, reconstructedYFrame, avgMAE] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
        for j = 1:nFrame
            PSNRFrame = psnr(reconstructedYFrame(:,:,j), Y(:,:,j));
            PSNRs(i, j) = PSNRFrame;
        end
        MAEs(i, :) = avgMAE;
    end
    figure
    for i = 1:size(blockSizes, 2)
        plot(x_frame,PSNRs(i, :),'DisplayName',strcat('i=', num2str(blockSizes(1, i))));
        hold on
    end
    legend('location', 'best');
    hold off
end

function varyN(yuvInputFileName, width, height, nFrame, x_frame)
    r = 4;
    blockSize = 8;
    ns = [1, 2, 3];
    PSNRs = zeros(size(ns, 2), nFrame);
    MAEs = zeros(size(ns, 2), nFrame);
    for i = 1:size(ns, 2)
        n = ns(1, i);
        [Y, reconstructedYFrame, avgMAE] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
        for j = 1:nFrame
            PSNRFrame = psnr(reconstructedYFrame(:,:,j), Y(:,:,j));
            PSNRs(i, j) = PSNRFrame;
        end
        MAEs(i, :) = avgMAE;
    end
    figure
    for i = 1:size(ns, 2)
        plot(x_frame,PSNRs(i, :),'DisplayName',strcat('n=', num2str(ns(1, i))));
        hold on
    end
    legend('location', 'best');
    hold off
end

function varyR(yuvInputFileName, width, height, nFrame, x_frame)
    n = 3;
    blockSize = 8;
    rs = [1, 4, 8];
    PSNRs = zeros(size(rs, 2), nFrame);
    MAEs = zeros(size(rs, 2), nFrame);
    for i = 1:size(rs, 2)
        r = rs(1, i);
        [Y, reconstructedYFrame, avgMAE] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
        for j = 1:nFrame
            PSNRFrame = psnr(reconstructedYFrame(:,:,j), Y(:,:,j));
            PSNRs(i, j) = PSNRFrame;
        end
        MAEs(i, :) = avgMAE;
    end
    figure
    for i = 1:size(rs, 2)
        plot(x_frame,PSNRs(i, :),'DisplayName',strcat('r=', num2str(rs(1, i))));
        hold on
    end
    legend('location', 'best');
    hold off
end