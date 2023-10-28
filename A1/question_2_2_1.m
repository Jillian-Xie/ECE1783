clc; clear; close all; 

param_8_2_3_1 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 3,'I_Period', 1 );
param_8_2_3_4 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 3,'I_Period', 4 );
param_8_2_3_10 = struct( 'yuvInputFileName', 'foreman420_cif.yuv','yuvOutputFileName', 'DecoderOutput\DecoderOutput.yuv','nFrame', 10,'width', 352,'height', 288,'blockSize', 8,'r', 2,'QP', 3,'I_Period', 10 );

[comparisonRatio, averagePSNR] = answer_2_2_1(param_8_2_3_1)
[comparisonRatio, averagePSNR] = answer_2_2_1(param_8_2_3_4)
[comparisonRatio, averagePSNR] = answer_2_2_1(param_8_2_3_10)


function [comparisonRatio, averagePSNR] = answer_2_2_1(param)
    originalBitcount = param.width * param.height * param.nFrame * 8;
    comparisonBitcount = double(0);
    totalPSNR = double(0);

    ex4_encoder(param.yuvInputFileName, param.nFrame, param.width, param.height, param.blockSize, param.r, param.QP, param.I_Period);
    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');
    ex4_decoder(param.nFrame, param.width, param.height, param.blockSize, param.QP, param.I_Period, QTCCoeffs, MDiffs);

    YOutput = importYOnly(param.yuvOutputFileName, param.width, param.height, param.nFrame);
    [YOriginal, U, V] = importYUV(param.yuvInputFileName, param.width, param.height, param.nFrame);
    
    for i=1:param.nFrame
        comparisonBitcount = comparisonBitcount + sum(strlength(QTCCoeffs(i,:)), "all") + sum(strlength(MDiffs(i,:)), "all");
        totalPSNR = totalPSNR + psnr(YOutput(:, :, i), YOriginal(:,:,i));
    end

    comparisonRatio = comparisonBitcount / originalBitcount;
    averagePSNR = totalPSNR / param.nFrame;

end