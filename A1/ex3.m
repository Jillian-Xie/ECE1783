function [Y, reconstructedY, avgMAE] = ex3(yuvInputFileName, nFrame, width, height, blockSize, r, n)
    MVOutputPath = 'MVOutput\';
    if ~exist(MVOutputPath,'dir')
        mkdir(MVOutputPath)
    end

    approximatedResidualOutputPath = 'approximatedResidualOutput\';
    if ~exist(approximatedResidualOutputPath,'dir')
        mkdir(approximatedResidualOutputPath)
    end

    absoluteResidualNoMCOutputPath = 'absoluteResidualNoMCOutput\';
    if ~exist(absoluteResidualNoMCOutputPath,'dir')
        mkdir(absoluteResidualNoMCOutputPath)
    end

    absoluteResidualWithMCOutputPath = 'absoluteResidualWithMCOutput\';
    if ~exist(absoluteResidualWithMCOutputPath,'dir')
        mkdir(absoluteResidualWithMCOutputPath)
    end

    encoderReconstructionOutputPath = 'encoderReconstructionOutput\';
    if ~exist(encoderReconstructionOutputPath,'dir')
        mkdir(encoderReconstructionOutputPath)
    end

    [Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
    paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
    firstRefFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);
    absoluteResidualNoMC = zeros(height, width, nFrame);
    absoluteResidualWithMC = zeros(height, width, nFrame);
    reconstructedY = uint8(zeros(height, width, nFrame));
    avgMAE = zeros(1, nFrame);
    referenceFrame = firstRefFrame;

    for currentFrameNum = 1:nFrame
        absoluteResidualNoMC(:,:,currentFrameNum) = uint8(abs(int32(paddingY(1:height,1:width,currentFrameNum)) - int32(referenceFrame(1:height, 1:width))));

        [MVCell, approximatedResidualCell, approximatedResidualFrame, reconstructedYFrame, avgMAEFrame] = ex3_motionEstimate(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, n);
        referenceFrame = reconstructedYFrame;
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

    plotResidual(absoluteResidualNoMC, nFrame, absoluteResidualNoMCOutputPath);
    plotResidual(absoluteResidualWithMC, nFrame, absoluteResidualWithMCOutputPath);
    
    ex3_decoder(nFrame, width, height, blockSize);
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