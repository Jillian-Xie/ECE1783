clear;
clc;

filepath = "data\test_cif.yuv";
height = 288;
width = 352;
%height = 144;
%width = 176;

nframes = 21;
I_Period = 21;


QP = 6;
RCflag = 4;


QP_delta = 1;
targetBR = "2 mbps";
startTime = posixtime(datetime('now'));
[psnrs1, bitCounts1] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime1 = endTime - startTime;
avgPSNR1 = mean(psnrs1);
totalBit1 = sum(bitCounts1);


QP_delta = 2;
startTime = posixtime(datetime('now'));
[psnrs2, bitCounts2] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime2 = endTime - startTime;
avgPSNR2 = mean(psnrs2);
totalBit2 = sum(bitCounts2);


QP_delta = 3;
startTime = posixtime(datetime('now'));
[psnrs3, bitCounts3] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime3 = endTime - startTime;
avgPSNR3 = mean(psnrs3);
totalBit3 = sum(bitCounts3);


