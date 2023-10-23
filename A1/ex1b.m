clc; clear; close all; 

yuvInputFileName = 'foreman420_cif.yuv';
rgbOutputPath = 'D:\ECE1783\A1\foremanRGB\';
width  = 352;
height = 288;
nFrame = 300;

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
[Yscale,Uscale,Vscale] = scaleYUV420To444(Y, U, V, width, height ,nFrame);
[R,G,B]=YUV2RGB(Yscale, Uscale, Vscale, width, height ,nFrame);

if ~exist(rgbOutputPath,'dir')
    mkdir(rgbOutputPath)
end

for i=1:nFrame
    im(:,:,1)=R(:,:,i);
    im(:,:,2)=G(:,:,i);
    im(:,:,3)=B(:,:,i);
    Image=uint8(im);
    imwrite(uint8(im),[rgbOutputPath, int2str(i), '.png']);
end

