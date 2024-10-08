function [Y,U,V] = importYUV(yuvFileName, width, height, nFrame)
    fid = fopen(yuvFileName,'r');           
    stream = fread(fid,'*uchar');   
    length = 1.5 * width * height;  

    Y = uint8(zeros(height, width, nFrame));
    U = uint8(zeros(height/2, width/2, nFrame));
    V = uint8(zeros(height/2, width/2, nFrame));

    for iFrame = 1:nFrame
        frame = stream((iFrame-1)*length+1:iFrame*length);

        % frame is of (width*height, 1) shape (i.e. column vector). We need
        % to reshape it by width * height then transpose to get raster
        % order
        yImage = reshape(frame(1:width*height), width, height);
        uImage = reshape(frame(width*height+1:1.25*width*height), width/2, height/2);
        vImage = reshape(frame(1.25*width*height+1:1.5*width*height), width/2, height/2);

        Y(:,:,iFrame) = uint8(yImage');
        U(:,:,iFrame) = uint8(uImage');
        V(:,:,iFrame) = uint8(vImage');
    end