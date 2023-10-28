function [Y, reconstructedY, avgMAE] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n)
    yuvInputFileNameSeparator = split(yuvInputFileName, '.');
    
    MVOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_MVOutput', filesep);
    if ~exist(MVOutputPath,'dir')
        mkdir(MVOutputPath)
    end
    
    referenceFrameOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_referenceFrames', filesep);
    if ~exist(referenceFrameOutputPath,'dir')
        mkdir(referenceFrameOutputPath)
    end
    
    sourceFrameOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_sourceFrames', filesep);
    if ~exist(sourceFrameOutputPath,'dir')
        mkdir(sourceFrameOutputPath)
    end
    
    predictedFrameOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_predictedFrames', filesep);
    if ~exist(predictedFrameOutputPath,'dir')
        mkdir(predictedFrameOutputPath)
    end

    absoluteResidualNoMCOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_absoluteResidualNoMCOutput', filesep);
    if ~exist(absoluteResidualNoMCOutputPath,'dir')
        mkdir(absoluteResidualNoMCOutputPath)
    end

    absoluteResidualWithMCOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_absoluteResidualWithMCOutput', filesep);
    if ~exist(absoluteResidualWithMCOutputPath,'dir')
        mkdir(absoluteResidualWithMCOutputPath)
    end

    approximatedResidualOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_approximatedResidualOutput', filesep);
    if ~exist(approximatedResidualOutputPath,'dir')
        mkdir(approximatedResidualOutputPath)
    end

    encoderReconstructionOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_encoderReconstructionOutput', filesep);
    if ~exist(encoderReconstructionOutputPath,'dir')
        mkdir(encoderReconstructionOutputPath)
    end

    [Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
    paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
    firstRefFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);
    absoluteResidualNoMC = zeros(height, width, nFrame);
    absoluteResidualWithMC = zeros(height, width, nFrame);
    predictedY = uint8(zeros(height, width, nFrame));
    reconstructedY = uint8(zeros(height, width, nFrame));
    referenceY = uint8(zeros(height, width, nFrame));
    sourceY = uint8(zeros(height, width, nFrame));
    avgMAE = zeros(1, nFrame);
    referenceFrame = firstRefFrame;

    for currentFrameNum = 1:nFrame
        referenceY(:, :, currentFrameNum) = referenceFrame(1:height, 1:width);
        sourceY(:, :, currentFrameNum) = paddingY(1:height, 1:width, currentFrameNum);
        
        absoluteResidualNoMC(:,:,currentFrameNum) = uint8(abs(int32(paddingY(1:height,1:width,currentFrameNum)) - int32(referenceFrame(1:height, 1:width))));

        [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedYFrame, predictedFrame, avgMAEFrame] = ex3_motionEstimate(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, n);
        referenceFrame = reconstructedYFrame;
        predictedY(:,:,currentFrameNum) = predictedFrame(1:height,1:width);
        reconstructedY(:,:,currentFrameNum) = reconstructedYFrame(1:height,1:width);
        avgMAE(1, currentFrameNum) = avgMAEFrame;

        absoluteResidualWithMC(:,:,currentFrameNum) = uint8(abs(approximatedResidualFrame(1:height,1:width)));

        MVFilePath = [MVOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(MVFilePath, 'MVCell');
        approximatedResidualFilePath = [approximatedResidualOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        save(approximatedResidualFilePath, 'approximatedResidualCell');

        YOnlyFilePath = [encoderReconstructionOutputPath, sprintf('%04d',currentFrameNum), '.yuv'];
        fid = createOrClearFile(YOnlyFilePath);
        fwrite(fid,uint8(reconstructedYFrame(1:height,1:width)),'uchar');
        fclose(fid);
    end

    plotResidual(sourceY, nFrame, sourceFrameOutputPath);
    plotResidual(referenceY, nFrame, referenceFrameOutputPath);
    plotResidual(predictedY, nFrame, predictedFrameOutputPath);
    plotResidual(absoluteResidualNoMC, nFrame, absoluteResidualNoMCOutputPath);
    plotResidual(absoluteResidualWithMC, nFrame, absoluteResidualWithMCOutputPath);
    
    ex3_decoder(yuvInputFileName, nFrame, width, height, blockSize);
end


function plotResidual(Residual, nFrame, rgbOutputPath)
    R = Residual;
    G = Residual;
    B = Residual;
    for i=1:nFrame
        im(:,:,1)=R(:,:,i);
        im(:,:,2)=G(:,:,i);
        im(:,:,3)=B(:,:,i);
        imwrite(uint8(im),[rgbOutputPath, sprintf('%04d',i), '.png']);
    end
end