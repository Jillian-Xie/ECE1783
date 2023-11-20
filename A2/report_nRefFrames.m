clc; clear; close all;

% config info

param_1 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 1, 'I_Period', 8 , 'nRefFrames', 1, 'VBSEnable', true, 'FMEEnable', false, 'FastME', false);
param_2 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 3 , 'nRefFrames', 2, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);
param_3 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 3 , 'nRefFrames', 3, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);
param_4 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 3 , 'nRefFrames', 4, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);

param_5 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 6 , 'nRefFrames', 1, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);
param_6 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 6 , 'nRefFrames', 2, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);
param_7 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 6 , 'nRefFrames', 3, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);
param_8 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 6 , 'nRefFrames', 4, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);

param_9 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 10 , 'nRefFrames', 1, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);
param_10 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 10 , 'nRefFrames', 2, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);
param_11 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 10 , 'nRefFrames', 3, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);
param_12 = struct( 'yuvOutputFileName', ['DecoderOutput' filesep 'outputYUV.yuv'], 'yuvInputFileName', 'synthetic.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 16, 'r', 4, 'QP', 4, 'I_Period', 10 , 'nRefFrames', 4, 'VBSEnable', false, 'FMEEnable', false, 'FastME', false);

% Plots
runAndDrawCurves("PSNR vs FrameIndex (qp = 1 i = 16 IPeriod = 8)", "PSNR", "FrameIndex", param_1);
% runAndDrawCurves("Bitcount vs FrameIndex (qp = 4 i = 16 IPeriod = 3)", "Bitcount", "FrameIndex", param_1, param_2, param_3, param_4);
% 
% runAndDrawCurves("PSNR vs FrameIndex (qp = 4 i = 16 IPeriod = 6)", "PSNR", "FrameIndex", param_5, param_6, param_7, param_8);
% runAndDrawCurves("Bitcount vs FrameIndex (qp = 4 i = 16 IPeriod = 6)", "Bitcount", "FrameIndex", param_5, param_6, param_7, param_8);
% 
% runAndDrawCurves("PSNR vs FrameIndex (qp = 4 i = 16 IPeriod = 10)", "PSNR", "FrameIndex", param_9, param_10, param_11, param_12);
% runAndDrawCurves("Bitcount vs FrameIndex (qp = 4 i = 16 IPeriod = 10)", "Bitcount", "FrameIndex", param_9, param_10, param_11, param_12);


function runAndDrawCurves(fig_title, y_axis, x_axis, varargin) % varargin: parameters
plotOutputPath = ['Plots' filesep];

y(1:varargin{1}.nFrame, 1:(nargin-3)) = double(0.0);
x(1:varargin{1}.nFrame, 1:(nargin-3)) = double(0.0);

y_encoder_time(1:(nargin-3)) = double(0.0);
x_encoder_time(1:(nargin-3)) = double(0.0);

y_decoder_time(1:(nargin-3)) = double(0.0);
x_decoder_time(1:(nargin-3)) = double(0.0);

legends = strings([nargin-3, 1]);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for i = 1:(nargin-3)
    legends(i, :) = "nRefFrames = " + int2str(varargin{i}.nRefFrames);
    x_encoder_time(i) = varargin{i}.nRefFrames;
    x_decoder_time(i) = varargin{i}.nRefFrames;
    
    Lambda = getLambda(varargin{i}.QP);

    tic
    reconstructedY = encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, varargin{i}.r, varargin{i}.QP, varargin{i}.I_Period, varargin{i}.nRefFrames, varargin{i}.VBSEnable, varargin{i}.FMEEnable, varargin{i}.FastME, Lambda);
    toc;

    y_encoder_time(i) = toc;

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    load('splits.mat', 'splits');

    tic
    decoder(varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, varargin{i}.QP, varargin{i}.I_Period, varargin{i}.VBSEnable, varargin{i}.FMEEnable, varargin{i}.FastME, QTCCoeffs, MDiffs, splits, false, false, false, false, reconstructedY);
    toc;

    y_decoder_time(i) = toc;

    YOutput = importYOnly(varargin{i}.yuvOutputFileName, varargin{i}.width, varargin{i}.height ,varargin{i}.nFrame);
    [YOriginal, U, V] = importYUV(varargin{i}.yuvInputFileName, varargin{i}.width, varargin{i}.height, varargin{i}.nFrame);

    for j=1:varargin{i}.nFrame
        if (y_axis == "PSNR")
            y(j, i) = psnr(YOutput(:, :, j), YOriginal(:,:,j));
        elseif (y_axis == "Bitcount")
            y(j, i) = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all");
        end

        if (x_axis == "FrameIndex")
            x(j, i) = j;
        elseif (x_axis == "Bitcount")
            if j == 1
                x(j, i) = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all");
            else
                x(j, i) = x(j - 1, i) + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all") + sum(strlength(splits(j,:)), "all");
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
saveas(gcf, fullfile(plotOutputPath + x_axis + '_' + y_axis + '_' + int2str(varargin{1}.blockSize) + '_' + int2str(varargin{1}.r) + '_' + int2str(varargin{1}.QP)+ '_' + int2str(varargin{1}.I_Period) + '.jpeg'));
delete(gcf);

plot([x_encoder_time' x_decoder_time'], [y_encoder_time' y_decoder_time'], '-o');
title("Execution Times (i = " + int2str(varargin{1}.blockSize) + " qp = " + int2str(varargin{1}.QP) + " IPeriod = " + int2str(varargin{1}.I_Period) + ")");
xlabel("nRefFrames");
ylabel("time(s)");
legend({'Encoder', 'Decoder'},'Location','southwest');
saveas(gcf, fullfile(plotOutputPath + "Execution_Times_" + x_axis + '_' + y_axis + '_' + int2str(varargin{1}.blockSize) + '_' + int2str(varargin{1}.r) + '_' + int2str(varargin{1}.QP) + int2str(varargin{1}.I_Period) + ".jpeg"));
end
