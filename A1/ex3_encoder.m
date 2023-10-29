function [Y, reconstructedY, avgMAE, residualMagnitude] = ex3_encoder(yuvInputFileName, nFrame, width, height, blockSize, r, n)
    yuvInputFileNameSeparator = split(yuvInputFileName, '.');
    
    % Check and create a bunch of directories to store intermidiate files
    % or plots
    
    % Directory to store MV for the decoder to read
    MVOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_MVOutput', filesep);
    if ~exist(MVOutputPath,'dir')
        mkdir(MVOutputPath)
    end
    
    % Directory to plot the references frames during the encoding process
    referenceFrameOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_referenceFrames', filesep);
    if ~exist(referenceFrameOutputPath,'dir')
        mkdir(referenceFrameOutputPath)
    end
    
    % Directory to plot the source frames during the encoding process
    sourceFrameOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_sourceFrames', filesep);
    if ~exist(sourceFrameOutputPath,'dir')
        mkdir(sourceFrameOutputPath)
    end
    
    % Directory to plot the predicted frames during the encoding process
    predictedFrameOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_predictedFrames', filesep);
    if ~exist(predictedFrameOutputPath,'dir')
        mkdir(predictedFrameOutputPath)
    end

    % Directory to plot the absolute residuals without motion compensation
    % during the encoding process
    absoluteResidualNoMCOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_absoluteResidualNoMCOutput', filesep);
    if ~exist(absoluteResidualNoMCOutputPath,'dir')
        mkdir(absoluteResidualNoMCOutputPath)
    end

    % Directory to plot the absolute residuals with motion compensation
    % during the encoding process
    absoluteResidualWithMCOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_absoluteResidualWithMCOutput', filesep);
    if ~exist(absoluteResidualWithMCOutputPath,'dir')
        mkdir(absoluteResidualWithMCOutputPath)
    end

    % Directory to store the residual matrix for the decoder to read
    approximatedResidualOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_approximatedResidualOutput', filesep);
    if ~exist(approximatedResidualOutputPath,'dir')
        mkdir(approximatedResidualOutputPath)
    end

    % Directory to store the encoder reconstructed Y to compare with
    % decoder results
    encoderReconstructionOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_encoderReconstructionOutput', filesep);
    if ~exist(encoderReconstructionOutputPath,'dir')
        mkdir(encoderReconstructionOutputPath)
    end

    [Y,~,~] = importYUV(yuvInputFileName, width, height ,nFrame);
    % pad the frames if the dimensions of Y is not devisible by blockSize
    paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
    % For the first frame, the reference frame is assumed to be gray (i.e.
    % 128)
    firstRefFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);
    % placeholders to store intermediate and return values
    absoluteResidualNoMC = zeros(height, width, nFrame);
    absoluteResidualWithMC = zeros(height, width, nFrame);
    predictedY = uint8(zeros(height, width, nFrame));
    reconstructedY = uint8(zeros(height, width, nFrame));
    referenceY = uint8(zeros(height, width, nFrame));
    sourceY = uint8(zeros(height, width, nFrame));
    avgMAE = zeros(1, nFrame);
    referenceFrame = firstRefFrame;
    
    residualMagnitude = [];

    for currentFrameNum = 1:nFrame
        referenceY(:, :, currentFrameNum) = referenceFrame(1:height, 1:width);
        sourceY(:, :, currentFrameNum) = paddingY(1:height, 1:width, currentFrameNum);
        
        % Absolute differences between the source frame and the reference
        % (previous) fram is the residual without motion compensation
        absoluteResidualNoMC(:,:,currentFrameNum) = uint8(abs(int32(paddingY(1:height,1:width,currentFrameNum)) - int32(referenceFrame(1:height, 1:width))));

        [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedYFrame, predictedFrame, avgMAEFrame] = ex3_motionEstimate(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, n);
        % Use the reconstructed Y as the reference for the next frame
        referenceFrame = reconstructedYFrame;
        predictedY(:,:,currentFrameNum) = predictedFrame(1:height,1:width);
        reconstructedY(:,:,currentFrameNum) = reconstructedYFrame(1:height,1:width);
        avgMAE(1, currentFrameNum) = avgMAEFrame;

        absoluteResidualWithMC(:,:,currentFrameNum) = uint8(abs(approximatedResidualFrame(1:height,1:width)));
        
        residualMagnitude = [residualMagnitude, sum(abs(approximatedResidualFrame(1:height,1:width)), 'all')];

        % save MV and residual for the decoder to read
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