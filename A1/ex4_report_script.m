clc; clear; close all;

% config info

param_8_2_0_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv', 'yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv', 'nFrame', 10, 'width', 352, 'height', 288, 'blockSize', 8, 'r', 2, 'QP', 0, 'I_Period', 1 );
param_8_2_0_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv', 'yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 0,'I_Period', 4 );
param_8_2_0_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 0,'I_Period', 10 );
param_8_2_3_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 3,'I_Period', 1 );
param_8_2_3_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 3,'I_Period', 4 );
param_8_2_3_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 3,'I_Period', 10 );
param_8_2_6_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 6,'I_Period', 1 );
param_8_2_6_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 6,'I_Period', 4 );
param_8_2_6_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 6,'I_Period', 10 );
param_8_2_9_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 9,'I_Period', 1 );
param_8_2_9_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 9,'I_Period', 4 );
param_8_2_9_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 9,'I_Period', 10 );

param_16_2_1_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 1,'I_Period', 1 );
param_16_2_1_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 1,'I_Period', 4 );
param_16_2_1_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 1,'I_Period', 10 );
param_16_2_4_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 4,'I_Period', 1 );
param_16_2_4_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 4,'I_Period', 4 );
param_16_2_4_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 4,'I_Period', 10 );
param_16_2_7_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 7,'I_Period', 1 );
param_16_2_7_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 7,'I_Period', 4 );
param_16_2_7_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 7,'I_Period', 10 );
param_16_2_10_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 10,'I_Period', 1 );
param_16_2_10_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 10,'I_Period', 4 );
param_16_2_10_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 16,'r', 2,'QP', 10,'I_Period', 10 );

% Part 1

runAndDrawTotalBitcountCurves(param_8_2_0_1);
runAndDrawTotalBitcountCurves(param_16_2_1_1);

% Part 2
% runAndDrawCurves("Bitcount vs FrameIndex (qp = 3 i = 8)", "FrameIndex", "Bitcount", param_8_2_3_1, param_8_2_3_4, param_8_2_3_10);
% runAndDrawCurves("Bitcount vs FrameIndex (qp = 4 i = 16)", "FrameIndex", "Bitcount", param_16_2_4_1, param_16_2_4_4, param_16_2_4_10);


function runAndDrawTotalBitcountCurves(param)
plotOutputPath = 'Plots\';
maxQP = int8(log2(param.blockSize) + 7);
y_encoder_time(1:(maxQP+1), 1:3) = double(0.0);
x_encoder_time(1:(maxQP+1), 1:3) = y_encoder_time;

y_decoder_time(1:(maxQP+1), 1:3) = y_encoder_time;
x_decoder_time(1:(maxQP+1), 1:3) = y_encoder_time;
y(1:(maxQP+1), 1:3) = double(0.0);
x(1:(maxQP+1), 1:3) = y;

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for qp = 0:maxQP
    % IPP = 1
    tic
    ex4_encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, param.blockSize, param.r, qp, 1);
    toc
    
    y_encoder_time(qp+1, 1) = toc;
    x_encoder_time(qp+1, 1) = qp;

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    
    tic
    ex4_decoder(param.nFrame, param.width, param.height, param.blockSize, qp, 1, QTCCoeffs, MDiffs);
    toc

    y_decoder_time(qp+1, 1) = toc;
    x_decoder_time(qp+1, 1) = qp;
    
    YOutput = importYOnly(param.yuvOutputFileName, param.width, param.height, param.nFrame);
    [YOriginal, U, V] = importYUV(param.yuvInputFileName, param.width, param.height, param.nFrame);

    for j=1:param.nFrame
          x(qp+1, 1) = x(qp+1, 1) + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
    end

    y(qp+1, 1) = psnr(YOutput, YOriginal);

    % IPP = 4
    tic
    ex4_encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, param.blockSize, param.r, qp, 4);
    toc
    
    y_encoder_time(qp+1, 2) = toc;
    x_encoder_time(qp+1, 2) = qp;

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    
    tic
    ex4_decoder(param.nFrame, param.width, param.height, param.blockSize, qp, 4, QTCCoeffs, MDiffs);
    toc

    y_decoder_time(qp+1, 2) = toc;
    x_decoder_time(qp+1, 2) = qp;
    
    YOutput = importYOnly(param.yuvOutputFileName, param.width, param.height, param.nFrame);
    [YOriginal, U, V] = importYUV(param.yuvInputFileName, param.width, param.height, param.nFrame);

    for j=1:param.nFrame
          x(qp+1, 2) = x(qp+1, 2) + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
    end

    y(qp+1, 2) = psnr(YOutput, YOriginal);

    % IPP = 10
    tic
    ex4_encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, param.blockSize, param.r, qp, 10);
    toc
    
    y_encoder_time(qp+1, 3) = toc;
    x_encoder_time(qp+1, 3) = qp;

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    
    tic
    ex4_decoder(param.nFrame, param.width, param.height, param.blockSize, qp, 10, QTCCoeffs, MDiffs);
    toc

    y_decoder_time(qp+1, 3) = toc;
    x_decoder_time(qp+1, 3) = qp;
    
    YOutput = importYOnly(param.yuvOutputFileName, param.width, param.height, param.nFrame);
    [YOriginal, U, V] = importYUV(param.yuvInputFileName, param.width, param.height, param.nFrame);

    for j=1:param.nFrame
          x(qp+1, 3) = x(qp+1, 3) + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
    end
    y(qp+1, 3) = psnr(YOutput, YOriginal);
end

plot(x, y);
title("PNSR vs TotalBitcount ( i = " + int2str(param.blockSize) + ")");
xlabel("TotalBitcount");
ylabel("PNSR");
legend({"IPP = 1", "IPP = 4", "IPP = 10"},'Location','southeast');
saveas(gcf, fullfile(plotOutputPath + "TotalBitcount_PNSR" + '_' + int2str(param.blockSize) + '.jpeg'));

plot(x_encoder_time, y_encoder_time);
title("EncodeTime vs QP ( i = " + int2str(param.blockSize) + ")");
xlabel("QP");
ylabel("EncodeTime");
legend({"IPP = 1", "IPP = 4", "IPP = 10"},'Location','southeast');
saveas(gcf, fullfile(plotOutputPath + "EncodeTime_QP" + '_' + int2str(param.blockSize) + '.jpeg'));

plot(x_decoder_time, y_decoder_time);
title("DecodeTime vs QP ( i = " + int2str(param.blockSize) + ")");
xlabel("QP");
ylabel("DecodeTime");
legend({"IPP = 1", "IPP = 4", "IPP = 10"},'Location','southeast');
saveas(gcf, fullfile(plotOutputPath + "DecodeTime_QP" + '_' + int2str(param.blockSize) + '.jpeg'));

end

function runAndDrawCurves(fig_title, x_axis, y_axis, varargin) % varargin: parameters
plotOutputPath = 'Plots\';

y(1:varargin{1}.nFrame, 1:(nargin-3)) = double(0.0);
x(1:varargin{1}.nFrame, 1:(nargin-3)) = y;

y_encoder_time(1:nargin-3) = double(0.0);
x_encoder_time(1:nargin-3) = y_encoder_time;

y_decoder_time(1:nargin-3) = y_encoder_time;
x_decoder_time(1:nargin-3) = y_encoder_time;

legends = strings([nargin-3, 1]);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for i = 1:(nargin-3)
    legends(i, :) = "IPP = " + int2str(varargin{i}.I_Period);
    x_encoder_time(i) = varargin{i}.I_Period;
    x_decoder_time(i) = varargin{i}.I_Period;

    tic
    ex4_encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, varargin{i}.r, varargin{i}.QP, varargin{i}.I_Period);
    toc;

    y_encoder_time(i) = toc;

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');

    tic
    ex4_decoder(varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, varargin{i}.QP, varargin{i}.I_Period, QTCCoeffs, MDiffs);
    toc;

    y_decoder_time(i) = toc;

    YOutput = importYOnly(varargin{i}.yuvOutputFileName, varargin{i}.width, varargin{i}.height ,varargin{i}.nFrame);
    [YOriginal, U, V] = importYUV(varargin{i}.yuvInputFileName, varargin{i}.width, varargin{i}.height, varargin{i}.nFrame);

    for j=1:varargin{i}.nFrame
        if (y_axis == "PSNR")
            y(j, i) = psnr(YOutput(:, :, j), YOriginal(:,:,j));
        elseif (y_axis == "Bitcount")
            y(j, i) = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
        end

        if (x_axis == "FrameIndex")
            x(j, i) = j;
        elseif (x_axis == "Bitcount")
            if j == 1
                x(j, i) = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
            else
                x(j, i) = x(j - 1, i) + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
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
saveas(gcf, fullfile(plotOutputPath + x_axis + '_' + y_axis + '_' + int2str(varargin{1}.blockSize) + '_' + int2str(varargin{1}.r) + '_' + int2str(varargin{1}.QP) + '.jpeg'));
delete(gcf);

plot([x_encoder_time' x_decoder_time'], [y_encoder_time' y_decoder_time'], '-o');
title("Execution Times (i = " + int2str(varargin{1}.blockSize) + " qp = " + int2str(varargin{1}.QP) + ")");
xlabel("IPP");
ylabel("time(s)");
legend({'Encoder', 'Decoder'},'Location','southwest');
saveas(gcf, fullfile(plotOutputPath + "Execution_Times_" + x_axis + '_' + y_axis + '_' + int2str(varargin{1}.blockSize) + '_' + int2str(varargin{1}.r) + '_' + int2str(varargin{1}.QP) + ".jpeg"));
end