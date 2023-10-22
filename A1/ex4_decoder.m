function ex4_decoder(nFrame, width, height, blockSize, QP)
    MVOutputPath = 'MVOutput\';
    ResidualOutputPath = 'approximatedResidualOutput\';
    assert(exist(MVOutputPath,'dir') > 0);
    assert(exist(ResidualOutputPath,'dir') > 0);
    
    DecoderOutputPath = 'DecoderOutput\';
    
    if ~exist(DecoderOutputPath,'dir')
        mkdir(DecoderOutputPath)
    end
    
    widthBlockNum = idivide(uint32(width), uint32(blockSize), 'ceil');
    heightBlockNum = idivide(uint32(height), uint32(blockSize), 'ceil');
    
    refFrame = uint8(zeros(width, height));
    % hypothetical reference frame at first
    for i = 1 : width
        for j = 1 : height
            refFrame(i, j) = 128;
        end
    end
    
    for currentFrameNum = 1:nFrame
        MVFilePath = [MVOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        ResidualFilePath = [ResidualOutputPath, sprintf('%04d',currentFrameNum), '.mat'];
        load(MVFilePath, "MVCell");
        load(ResidualFilePath, "approximatedResidualCell");
        
        curFrame = uint8(zeros(width, height));
        
        for i = 1:widthBlockNum
            for j = 1:heightBlockNum
                cell1 = MVCell(i,j);
                horizontalOffset = cell1{1,1}(1);
                verticalOffset = cell1{1,1}(2);
                
                cell2 = approximatedResidualCell(i,j);
                cell2 = rescaling(cell2, QP);
                cell2 = idct2(cell2);
                
                for ii = 1:blockSize
                    for jj = 1:blockSize
                        horizontalIndex = (i - 1) * blockSize + ii;
                        verticalIndex = (j - 1) * blockSize + jj;
                        
                        if horizontalIndex > width || verticalIndex > height
                            continue
                        end
                        
                        % current frame = MV in the ref frame + residual
                        curFrame(horizontalIndex, verticalIndex) = uint8(int32(refFrame(horizontalIndex + horizontalOffset, verticalIndex + verticalOffset)) + cell2{1,1}(ii, jj));
                    end
                end
            end
        end
        
        YOnlyFilePath = [DecoderOutputPath, sprintf('%04d',currentFrameNum), '.yuv'];
        fid = createOrClearFile(YOnlyFilePath);
        fwrite(fid,uint8(curFrame(:,:)),'uchar');
        fclose(fid);
        
        refFrame = curFrame;
    end
end