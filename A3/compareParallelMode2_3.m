clc; clear; close all;
parpool(4);
yuvInputFileName = 'CIF.yuv';
nFrame = 21;
width  = uint32(352);
height = uint32(288);
blockSize = 16;
r = 4;
QP = 5;
I_Period = 10;
RCFlag = 0;
QPs = [0 1 2 3 4 5 6 7 8 9 10 11];
targetBR = 2400000;
frameRate = 30;
nRefFrames = 1;

VBSEnable = true;
FMEEnable = true;
FastME = true;

parallelModes = [0, 2, 3];
encodedStreams = {};
encodingTimes = [];
dQPLimit = 2;

for i = 1:length(parallelModes)
    parallelMode = parallelModes(i);
    fprintf('Testing with Parallel Mode %d\n', parallelMode);

    tic;
    if parallelMode == 3
        % Use the parallel mode 3 encoder
        reconstructedY = encoder_parallelMode3(yuvInputFileName, nFrame, width, height, ...
            blockSize, r, QP, I_Period, VBSEnable, FMEEnable, FastME);
    else
        % Use the standard encoder
        reconstructedY = encoder(yuvInputFileName, nFrame, width, height, blockSize, ...
            r, QP, I_Period, nRefFrames, VBSEnable, FMEEnable, FastME, RCFlag, ...
            targetBR, frameRate, QPs, {}, parallelMode, dQPLimit);
    end
    encodingTime = toc;
    fprintf('Encoding Time: %f seconds\n', encodingTime);
    
    encodedStreams{end+1} = reconstructedY;
    encodingTimes(end+1) = encodingTime;
end

% Comparing encoded streams and encoding times
fprintf('\nComparing Encoded Streams and Encoding Times:\n');
for i = 1:length(parallelModes)
    fprintf('Parallel Mode %d: Encoding Time = %f seconds\n', parallelModes(i), encodingTimes(i));
end

% Assuming encodedStreams{1} corresponds to Type 0, encodedStreams{2} to Type 2, and encodedStreams{3} to Type 3
isIdenticalType2 = isequal(encodedStreams{1}, encodedStreams{2});
isIdenticalType3 = isequal(encodedStreams{1}, encodedStreams{3});

fprintf('Encoded stream is identical in Type 2 and Type 0: %s\n', boolToYesNo(isIdenticalType2));
fprintf('Encoded stream is identical in Type 3 and Type 0: %s\n', boolToYesNo(isIdenticalType3));

delete(gcp('nocreate'));

function yesNoStr = boolToYesNo(boolVal)
    if boolVal
        yesNoStr = 'Yes';
    else
        yesNoStr = 'No';
    end
end
