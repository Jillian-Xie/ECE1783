clc; clear; 

yuvInputFileName = 'foreman420_cif.yuv';
yuvOutputFileName = 'foreman444_cif.yuv';
width  = 352;
height = 288;
nFrame = 300;

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);
[Yscale,Uscale,Vscale] = scaleYUV(Y, U, V, width, height ,nFrame);

fid=fopen(yuvOutputFileName,'w');

for i=1:300
    fwrite(fid,uint8(Yscale(:,:,i)),'uchar');
    fwrite(fid,uint8(Uscale(:,:,i)),'uchar');
    fwrite(fid,uint8(Vscale(:,:,i)),'uchar');
end

fclose(fid);


function [Yscale,Uscale,Vscale] = scaleYUV(Y, U, V, width, height ,nFrame)
    Yscale = uint8(Y);
    Uscale = uint8(zeros(height, width, nFrame));
    Vscale = uint8(zeros(height, width, nFrame));

    for iFrame = 1:nFrame
        for i = 1:width/2
            for j = 1:height/2
                Uval = U(j,i,iFrame);
                Vval = V(j,i,iFrame);
                ii = 1+(i-1).*2;
                jj = 1+(j-1).*2;

                Uscale(jj+1,ii,iFrame) = Uval;
                Uscale(jj,ii+1,iFrame) = Uval;
                Uscale(jj+1,ii+1,iFrame) = Uval;
                Uscale(jj,ii,iFrame) = Uval;

                Vscale(jj+1,ii,iFrame) = Vval;
                Vscale(jj,ii+1,iFrame) = Vval;
                Vscale(jj+1,ii+1,iFrame) = Vval;
                Vscale(jj,ii,iFrame) = Vval;
            end
        end
    end
end