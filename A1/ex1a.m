clc; clear; 

yuvInputFileName = 'foreman420_cif.yuv';
yuvOutputFileName = 'foreman444_cif.yuv';
width  = 352;
height = 288;
nFrame = 300;

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
[Yscale,Uscale,Vscale] = scaleYUV420To444(Y, U, V, width, height ,nFrame);

outputFileExist = exist(yuvOutputFileName, 'file');

if outputFileExist == 2
    fid=fopen(yuvOutputFileName,'w');
    fclose(fid);
end

fid=fopen(yuvOutputFileName,'a');

for i=1:nFrame
    fwrite(fid,uint8(Yscale(:,:,i)),'uchar');
    fwrite(fid,uint8(Uscale(:,:,i)),'uchar');
    fwrite(fid,uint8(Vscale(:,:,i)),'uchar');
end

fclose(fid);
