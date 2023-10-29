function ex3_decoder(yuvInputFileName, nFrame, width, height, blockSize)
    yuvInputFileNameSeparator = split(yuvInputFileName, '.');
    
    % read the files dumped by the encoder
    MVOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_MVOutput', filesep);
    ResidualOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_approximatedResidualOutput', filesep);
    assert(exist(MVOutputPath,'dir') > 0);
    assert(exist(ResidualOutputPath,'dir') > 0);
    
    DecoderOutputPath = strcat('ex3Output', filesep, 'ex3_', yuvInputFileNameSeparator{1,1}, '_i', num2str(blockSize), '_DecoderOutput', filesep);
    if ~exist(DecoderOutputPath,'dir')
        mkdir(DecoderOutputPath)
    end
    
    widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
    heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');
    
    refFrame = uint8(zeros(height, width));
    % hypothetical reference frame at first
    for i = 1 : height
        for j = 1 : width
            refFrame(i, j) = 128;
        end
    end
    
    for currentFrameNum = 1:nFrame
        MVFilePath = [MVOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        ResidualFilePath = [ResidualOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        load(MVFilePath, "MVCell");
        load(ResidualFilePath, "approximatedResidualCell");
        
        curFrame = uint8(zeros(height, width));
        
        for i = 1:heightBlockNum
            for j = 1:widthBlockNum
                cell1 = MVCell(i,j);
                horizontalOffset = cell1{1,1}(1);
                verticalOffset = cell1{1,1}(2);
                
                cell2 = approximatedResidualCell(i,j);
                
                for ii = 1:blockSize
                    for jj = 1:blockSize
                        verticalIndex = (i - 1) * blockSize + ii;
                        horizontalIndex = (j - 1) * blockSize + jj;
                        
                        % don't need to fill pixels that's outside of the
                        % frame
                        if horizontalIndex > width || verticalIndex > height
                            continue
                        end
                        
                        % current frame = MV in the ref frame + residual
                        curFrame(verticalIndex, horizontalIndex) = uint8(int32(refFrame(verticalIndex + verticalOffset, horizontalIndex + horizontalOffset)) + cell2{1,1}(ii, jj));
                    end
                end
            end
        end
        
        % save the Y-only file for comparison
        YOnlyFilePath = [DecoderOutputPath, sprintf('%04d',currentFrameNum), '.yuv'];
        fid = createOrClearFile(YOnlyFilePath);
        fwrite(fid,uint8(curFrame(1:height,1:width)),'uchar');
        fclose(fid);
        
        refFrame = curFrame;
    end
end