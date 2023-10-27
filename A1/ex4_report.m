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

% % Part 1
% runAndDrawCurves("PSNR vs Bitcount (qp = 0 i = 8)", "Bitcount", "PSNR", param_8_2_0_1, param_8_2_0_4, param_8_2_0_10);
% runAndDrawCurves("PSNR vs Bitcount (qp = 3 i = 8)", "Bitcount", "PSNR", param_8_2_3_1, param_8_2_3_4, param_8_2_3_10);
% runAndDrawCurves("PSNR vs Bitcount (qp = 6 i = 8)", "Bitcount", "PSNR", param_8_2_6_1, param_8_2_6_4, param_8_2_6_10);
% runAndDrawCurves("PSNR vs Bitcount (qp = 9 i = 8)", "Bitcount", "PSNR", param_8_2_9_1, param_8_2_9_4, param_8_2_9_10);
% 
% runAndDrawCurves("PSNR vs Bitcount (qp = 1 i = 16)", "Bitcount", "PSNR", param_16_2_1_1, param_16_2_1_4, param_16_2_1_10);
% runAndDrawCurves("PSNR vs Bitcount (qp = 4 i = 16)", "Bitcount", "PSNR", param_16_2_4_1, param_16_2_4_4, param_16_2_4_10);
% runAndDrawCurves("PSNR vs Bitcount (qp = 7 i = 16)", "Bitcount", "PSNR", param_16_2_7_1, param_16_2_7_4, param_16_2_7_10);
% runAndDrawCurves("PSNR vs Bitcount (qp = 10 i = 16)", "Bitcount", "PSNR", param_16_2_10_1, param_16_2_10_4, param_16_2_10_10);

% Part 2
runAndDrawCurves("Bitcount vs FrameIndex (qp = 3 i = 8)", "FrameIndex", "Bitcount", param_8_2_3_1, param_8_2_3_4, param_8_2_3_10);
runAndDrawCurves("Bitcount vs FrameIndex (qp = 4 i = 16)", "FrameIndex", "Bitcount", param_16_2_4_1, param_16_2_4_4, param_16_2_4_10);

