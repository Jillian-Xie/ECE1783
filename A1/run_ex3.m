clc; clear; close all; 

yuvInputFileName = 'foreman420_cif.yuv';

width  = uint32(352);
height = uint32(288);

nFrame = uint32(10);
x_frame = [1:nFrame];


r = 4;
n = 3;
blockSizes = [2, 8, 64];
PSNRs = zeros(size(blockSizes, 2), nFrame);
MAEs = zeros(size(blockSizes, 2), nFrame);
for i = 1:size(blockSizes, 2)
    blockSize = blockSizes(1, i);
%     disp(blockSize);
    [Y, reconstructedYFrame, avgMAE] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n);
    for j = 1:nFrame
        PSNRFrame = psnr(reconstructedYFrame(:,:,j), Y(:,:,j));
%         disp('mse:');
%         disp(immse(reconstructedYFrame(:,:,j), Y(:,:,j)));
        PSNRs(i, j) = PSNRFrame;
    end
    MAEs(i, :) = avgMAE;
end
figure
for i = 1:size(blockSizes, 2)
    plot(x_frame,PSNRs(i, :),'DisplayName',strcat('i=', num2str(blockSizes(1, i))));
%     disp(PSNRs(i, :));
%     disp(MAEs(i, :));
    hold on
end
legend('location', 'best');
hold off
