function Y = importYOnly(yuvFileName, width, height, nFrame)
    fid = fopen(yuvFileName,'r');           
    stream = fread(fid,'*uchar');   
    length = width * height;  

    Y = uint8(zeros(height, width, nFrame));

    for iFrame = 1:nFrame
        frame = stream((iFrame-1)*length+1:iFrame*length);

        % frame is of (width*height, 1) shape (i.e. column vector). We need
        % to reshape it by width * height then transpose to get raster
        % order
        yImage = reshape(frame(1:width*height), width, height);

        Y(:,:,iFrame) = uint8(yImage');
    end