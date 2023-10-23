function convertToRGBandDump(Y, U, V, width, height ,nFrame, rgbOutputPath)
    % convert it to rgb to verify
    [Yscale,Uscale,Vscale] = scaleYUV420To444(Y, U, V, width, height ,nFrame);
    [R,G,B] = YUV2RGB(Yscale, Uscale, Vscale, width, height ,nFrame);

    for i=1:nFrame
        im(:,:,1)=R(:,:,i);
        im(:,:,2)=G(:,:,i);
        im(:,:,3)=B(:,:,i);
        imwrite(uint8(im),[rgbOutputPath, sprintf('%04d',i), '.png']);
    end
end