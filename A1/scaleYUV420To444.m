function [Yscale,Uscale,Vscale] = scaleYUV420To444(Y, U, V, width, height ,nFrame)
    Yscale = uint8(Y);
    Uscale = uint8(zeros(height, width, nFrame));
    Vscale = uint8(zeros(height, width, nFrame));

    for iFrame = 1:nFrame
        for i = 1:height/2
            for j = 1:width/2
                Uval = U(i,j,iFrame);
                Vval = V(i,j,iFrame);
                ii = 1+(i-1)*2;
                jj = 1+(j-1)*2;

                Uscale(ii,jj+1,iFrame) = Uval;
                Uscale(ii+1,jj,iFrame) = Uval;
                Uscale(ii+1,jj+1,iFrame) = Uval;
                Uscale(ii,jj,iFrame) = Uval;

                Vscale(ii,jj+1,iFrame) = Vval;
                Vscale(ii+1,jj,iFrame) = Vval;
                Vscale(ii+1,jj+1,iFrame) = Vval;
                Vscale(ii,jj,iFrame) = Vval;
            end
        end
    end
end