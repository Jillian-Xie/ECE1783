function ex4_encoder(yuvInputFileName, nFrame, width, height, blockSize, r, QP, I_Period)
reconstructedY = zeros(width, height, nFrame);

encoderReconstructionOutputPath = 'encoderReconstructionOutput\';
if ~exist(encoderReconstructionOutputPath,'dir')
    mkdir(encoderReconstructionOutputPath)
end

encoderReconstructionRGBOutputPath = 'encoderReconstructionOutputRGB\';
if ~exist(encoderReconstructionRGBOutputPath,'dir')
    mkdir(encoderReconstructionRGBOutputPath)
end

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
paddingY = paddingFrames(Y, blockSize, width, height, nFrame);
referenceFrame(1:size(paddingY,1),1:size(paddingY,2)) = uint8(128);

widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');

QTCCoeffs = strings([nFrame, widthBlockNum * heightBlockNum]);
MDiffs = strings([nFrame, 1]);

for currentFrameNum = 1:nFrame
    if rem(currentFrameNum,I_Period) == 1
        % first frame needs to be I frame
        [QTCCoeffsFrame, MDiffsFrame, reconstructedFrame] = intraPrediction(paddingY(:,:,currentFrameNum), blockSize, QP);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        referenceFrame = reconstructedFrame;
    else
        [QTCCoeffsFrame, MDiffsFrame, reconstructedFrame] = interPrediction(referenceFrame, paddingY(:,:,currentFrameNum), blockSize, r, QP);
        QTCCoeffs(currentFrameNum, :) = QTCCoeffsFrame;
        MDiffs(currentFrameNum, 1) = MDiffsFrame;
        referenceFrame = reconstructedFrame;
    end
    reconstructedY(:,:,currentFrameNum) = reconstructedFrame';
    im(:,:,1)=reconstructedFrame;
    im(:,:,2)=reconstructedFrame;
    im(:,:,3)=reconstructedFrame;
    imwrite(uint8(im),[encoderReconstructionRGBOutputPath, sprintf('%04d',currentFrameNum), '.png']);

end

save('QTCCoeffs.mat', 'QTCCoeffs');
save('MDiffs.mat', 'MDiffs');

YOnlyFilePath = [encoderReconstructionOutputPath, 'EncoderOutput', '.yuv'];
fid = createOrClearFile(YOnlyFilePath);
for i=1:nFrame
    fwrite(fid,uint8(reconstructedY(:,:,i)),'uchar');
end
fclose(fid);
