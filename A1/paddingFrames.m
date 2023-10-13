function frames = paddingFrames(Y, blockSize, width, height, nFrame)

    horizontal = idivide(uint32(width), uint32(blockSize), 'ceil');
    vertical = idivide(uint32(height), uint32(blockSize), 'ceil');
    frames = uint8(zeros(horizontal*blockSize, vertical*blockSize, nFrame));
    frames(1:width,1:height,:) = Y;
    
    if(rem(width,blockSize)~=0)
        frames(width+1:horizontal*blockSize,:)=uint8(128);
    end
    if(rem(height,blockSize)~=0)
        frames(:,height+1:vertical*blockSize,:)=uint8(128);
    end
    
end