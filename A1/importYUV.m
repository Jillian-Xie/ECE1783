function [Y,U,V] = importYUV(yuvFileName, width, height, nFrame)
    fid = fopen(yuvFileName,'r');           
    stream = fread(fid,'*uchar');   
    length = 1.5 * width * height;  

    Y = uint8(zeros(width, height, nFrame));
    U = uint8(zeros(width/2, height/2, nFrame));
    V = uint8(zeros(width/2, height/2, nFrame));

    for iFrame = 1:nFrame
        frame = stream((iFrame-1)*length+1:iFrame*length);

        yImage = reshape(frame(1:width*height), width, height);
        uImage = reshape(frame(width*height+1:1.25*width*height), width/2, height/2);
        vImage = reshape(frame(1.25*width*height+1:1.5*width*height), width/2, height/2);

        Y(:,:,iFrame) = uint8(yImage);
        U(:,:,iFrame) = uint8(uImage);
        V(:,:,iFrame) = uint8(vImage);
    end