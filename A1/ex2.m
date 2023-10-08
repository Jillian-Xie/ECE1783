clc; clear; close all; 

yuvInputFileName = 'foreman420_cif.yuv';
YOnlyOutputPath = 'D:\ECE1783\A1\YOnly\';

width  = 352;
height = 288;
nFrame = 300;
blockSize = 2;

rgbOutputPath = ['D:\ECE1783\A1\rgbAfterAvgBlockSize', int2str(blockSize), '\'];

[Y,U,V] = importYUV(yuvInputFileName, width, height ,nFrame);

if ~exist(YOnlyOutputPath,'dir')
    mkdir(YOnlyOutputPath)
end

if ~exist(rgbOutputPath,'dir')
    mkdir(rgbOutputPath)
end

for i=1:nFrame
    % part a
    YOnlyFilePath = [YOnlyOutputPath, sprintf('%04d',i), '.yuv'];
    fid = createOrClearFile(YOnlyFilePath);
    fwrite(fid,uint8(Y(:,:,i)),'uchar');
    fclose(fid);
    
    % part b, c, d
    YAvg = replaceBlocksWithAvg(Y(:,:,i), uint32(blockSize), uint32(width), uint32(height));
    
    Y(:,:,i) = uint8(YAvg);
end

% convert it to rgb to verify
[Yscale,Uscale,Vscale] = scaleYUV420To444(Y, U, V, width, height ,nFrame);
[R,G,B]=YUV2RGB(Yscale, Uscale, Vscale, width, height ,nFrame);

for i=1:nFrame
    im(:,:,1)=R(:,:,i)';
    im(:,:,2)=G(:,:,i)';
    im(:,:,3)=B(:,:,i)';
    Image=uint8(im);
    imwrite(uint8(im),[rgbOutputPath, sprintf('%04d',i), '.png']);
end

% helper function to slice Y into blocks and returns averaged Y within each block
function YAvg = replaceBlocksWithAvg(Y, blockSize, width, height)
    horizontal = idivide(width, blockSize, 'ceil');
    vertical = idivide(height, blockSize, 'ceil');
    
    YAvg = uint8(zeros(width, height));
    
    for i = 1:horizontal
        for j = 1:vertical
            sum = uint32(0);
            % go through the block to find sum
            for ii = 1:blockSize
                for jj = 1:blockSize
                    horizontalIndex = (i - 1) * blockSize + ii;
                    verticalIndex = (j - 1) * blockSize + jj;
                    
                    if horizontalIndex > width || verticalIndex > height
                        incre = uint32(128); % padded region is grey
                    else
                        incre = uint32(Y(horizontalIndex, verticalIndex));
                    end
                    
                    sum = sum + incre;
                end
            end
            
            avg = uint8(idivide(sum, blockSize * blockSize, 'round')); 
                        
            % assign the sum to each block
            for ii = 1:blockSize
                for jj = 1:blockSize
                    horizontalIndex = (i - 1) * blockSize + ii;
                    verticalIndex = (j - 1) * blockSize + jj;
                    
                    if horizontalIndex > width || verticalIndex > height
                        continue;
                    else
                        YAvg(horizontalIndex, verticalIndex) = avg;
                    end
                end
            end
        end
    end
end