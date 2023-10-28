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