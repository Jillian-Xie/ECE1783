function frames = paddingFrames(Y, blockSize, width, height, nFrame)

    horizontal = idivide(uint32(width), uint32(blockSize), 'ceil');
    vertical = idivide(uint32(height), uint32(blockSize), 'ceil');
    frames = int32(zeros(vertical*blockSize, horizontal*blockSize, nFrame));
    frames(1:height, 1:width, :) = Y;
    
    % pad with gray if necessary
    if(rem(width,blockSize)~=0)
        frames(:, width+1:horizontal*blockSize, :)=int32(128);
    end
    if(rem(height,blockSize)~=0)
        frames(height+1:vertical*blockSize,:,:)=int32(128);
    end
    
end