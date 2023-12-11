clear;
clc;

filepath = "data\test_cif.yuv";
height = 288;
width = 352;
%height = 144;
%width = 176;

nframes = 21;
I_Period = 21;
QP_delta = 0;

QP = 6;


RCflag = 1;
targetBR = "2 mbps";
[psnrs1, bitCounts1] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();

RCflag = 2;
targetBR = "2 mbps";
[psnrs2, bitCounts2] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();

RCflag = 3;
targetBR = "2 mbps";
[psnrs3, bitCounts3] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();

RCflag = 4;
targetBR = "2 mbps";
QP_delta = 1;
[psnrs4, bitCounts4] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
QP_delta = 0;


RCflag = 0;
QP = 3;
targetBR = "";
startTime = posixtime(datetime('now'));
[psnrs03, bitCounts03] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime03 = endTime - startTime;
avgPSNR03 = mean(psnrs03);
totalBit03 = sum(bitCounts03);

RCflag = 0;
QP = 6;
targetBR = "";
startTime = posixtime(datetime('now'));
[psnrs06, bitCounts06] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime06 = endTime - startTime;
avgPSNR06 = mean(psnrs06);
totalBit06 = sum(bitCounts06);

RCflag = 0;
QP = 9;
targetBR = "";
startTime = posixtime(datetime('now'));
[psnrs09, bitCounts09] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime09 = endTime - startTime;
avgPSNR09 = mean(psnrs09);
totalBit09 = sum(bitCounts09);

RCflag = 1;
targetBR = "7 mbps";
startTime = posixtime(datetime('now'));
[psnrs11, bitCounts11] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime11 = endTime - startTime;
avgPSNR11 = mean(psnrs11);
totalBit11 = sum(bitCounts11);

RCflag = 1;
targetBR = "2.4 mbps";
startTime = posixtime(datetime('now'));
[psnrs12, bitCounts12] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime12 = endTime - startTime;
avgPSNR12 = mean(psnrs12);
totalBit12 = sum(bitCounts12);

RCflag = 1;
targetBR = "360 kbps";
startTime = posixtime(datetime('now'));
[psnrs13, bitCounts13] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime13 = endTime - startTime;
avgPSNR13 = mean(psnrs13);
totalBit13 = sum(bitCounts13);

RCflag = 2;
targetBR = "7 mbps";
startTime = posixtime(datetime('now'));
[psnrs21, bitCounts21] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime21 = endTime - startTime;
avgPSNR21 = mean(psnrs21);
totalBit21 = sum(bitCounts21);

RCflag = 2;
targetBR = "2.4 mbps";
startTime = posixtime(datetime('now'));
[psnrs22, bitCounts22] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime22 = endTime - startTime;
avgPSNR22 = mean(psnrs22);
totalBit22 = sum(bitCounts22);

RCflag = 2;
targetBR = "360 kbps";
startTime = posixtime(datetime('now'));
[psnrs23, bitCounts23] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime23 = endTime - startTime;
avgPSNR23 = mean(psnrs23);
totalBit23 = sum(bitCounts23);

RCflag = 3;
targetBR = "7 mbps";
startTime = posixtime(datetime('now'));
[psnrs31, bitCounts31] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime31 = endTime - startTime;
avgPSNR31 = mean(psnrs31);
totalBit31 = sum(bitCounts31);

RCflag = 3;
targetBR = "2.4 mbps";
startTime = posixtime(datetime('now'));
[psnrs32, bitCounts32] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime32 = endTime - startTime;
avgPSNR32 = mean(psnrs32);
totalBit32 = sum(bitCounts32);

RCflag = 3;
targetBR = "360 kbps";
startTime = posixtime(datetime('now'));
[psnrs33, bitCounts33] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime33 = endTime - startTime;
avgPSNR33 = mean(psnrs33);
totalBit33 = sum(bitCounts33);

RCflag = 4;
QP_delta = 1;
targetBR = "7 mbps";
startTime = posixtime(datetime('now'));
[psnrs41, bitCounts41] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime41 = endTime - startTime;
avgPSNR41 = mean(psnrs41);
totalBit41 = sum(bitCounts41);

RCflag = 4;
targetBR = "2.4 mbps";
startTime = posixtime(datetime('now'));
[psnrs42, bitCounts42] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime42 = endTime - startTime;
avgPSNR42 = mean(psnrs42);
totalBit42 = sum(bitCounts42);

RCflag = 4;
targetBR = "1 mbps";
startTime = posixtime(datetime('now'));
[psnrs43, bitCounts43] = rcEncoder(filepath, width, height, nframes,  QP, I_Period, RCflag, targetBR, QP_delta).encode();
endTime = posixtime(datetime('now'));
executionTime43 = endTime - startTime;
avgPSNR43 = mean(psnrs43);
totalBit43 = sum(bitCounts43);
QP_delta = 0;

% decode
% rcDecoder("output/test_cif/").decode();


figure(2);
x0 = [totalBit09 / 1000, totalBit06 / 1000, totalBit03 / 1000];
y0 = [avgPSNR09, avgPSNR06, avgPSNR03];
x1 = [totalBit13 / 1000, totalBit12 / 1000, totalBit11 / 1000];
y1 = [avgPSNR13, avgPSNR12, avgPSNR11];
x2 = [totalBit23 / 1000, totalBit22 / 1000, totalBit21 / 1000];
y2 = [avgPSNR23, avgPSNR22, avgPSNR21];
x3 = [totalBit33 / 1000, totalBit32 / 1000, totalBit31 / 1000];
y3 = [avgPSNR33, avgPSNR32, avgPSNR31];
x4 = [totalBit43 / 1000, totalBit42 / 1000, totalBit41 / 1000];
y4 = [avgPSNR43, avgPSNR42, avgPSNR41];
plot(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4);
legend("RCFlag=0", "RCFlag=1", "RCFlag=2", "RCFlag=3", "RCFlag=4", 'Location', 'southeast');
xlabel("bit rate (kbps)");
ylabel("psnr");
title("RD graph");

figure(3);
x = 1 : 21;
plot(x, psnrs1, x, psnrs2, x, psnrs3, x, psnrs4);
legend("RCFlag=1", "RCFlag=2", "RCFlag=3", "RCFlag=4");
xlabel("frame number");
ylabel("psnr");
title("Per frame PSNR graph for 2 mbps");