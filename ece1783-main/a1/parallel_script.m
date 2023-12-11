clear;
clc;

filepath = "data\CIF.yuv";
height = 288;
width = 352;


nframes = 21;
I_Period = 10;
QP = 5;
RCflag = 0;
targetBR = "2 mbps";

ParallelMode = 0;
startTime = posixtime(datetime('now'));
[psnr0, bitcounts0] = parallelEncoder(filepath, width, height, nframes, QP, I_Period, ParallelMode, RCflag, targetBR).encode();
endTime = posixtime(datetime('now'));
executionTime0 = endTime - startTime;

ParallelMode = 1;
startTime = posixtime(datetime('now'));
[psnr1, bitcounts1] = parallelEncoder(filepath, width, height, nframes, QP, I_Period, ParallelMode, RCflag, targetBR).encode();
endTime = posixtime(datetime('now'));
executionTime1 = endTime - startTime;

ParallelMode = 2;
startTime = posixtime(datetime('now'));
[psnr2, bitcounts2] = parallelEncoder(filepath, width, height, nframes, QP, I_Period, ParallelMode, RCflag, targetBR).encode();
endTime = posixtime(datetime('now'));
executionTime2 = endTime - startTime;


ParallelMode = 3;
startTime = posixtime(datetime('now'));
[psnr3, bitcounts3] = parallelEncoder(filepath, width, height, nframes, QP, I_Period, ParallelMode, RCflag, targetBR).encode();
endTime = posixtime(datetime('now'));
executionTime3 = endTime - startTime;

delete(gcp())

