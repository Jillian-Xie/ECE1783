function [R, G, B] = YUV2RGB(Y, U, V, width, height, nFrame)

R = uint8(zeros(width, height, nFrame));
G = uint8(zeros(width, height, nFrame));
B = uint8(zeros(width, height, nFrame));

m=[1.164 0 1.596
   1.164 -0.392 -0.813
   1.164 2.017 0];

for k=1:nFrame
    for i=1:width
        for j=1:height
            n=[double(Y(i,j,k))-16
               double(U(i,j,k))-128 
               double(V(i,j,k))-128];
            im=m*n;
            R(i,j,k)=im(1);
            G(i,j,k)=im(2);
            B(i,j,k)=im(3);
        end
    end
end
