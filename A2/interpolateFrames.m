function interpolatedFrames = interpolateFrames(refFrames, blockSize)
% Determine the size of the interpolated frames
[height, width, numFrames] = size(refFrames);
interpolatedHeight = (2*height-2*blockSize+1)*blockSize;
interpolatedWidth = (2*width-2*blockSize+1)*blockSize;

% Initialize the interpolated frames
interpolatedFrames = zeros(interpolatedHeight, interpolatedWidth, numFrames);

% Perform interpolation for each reference frame
for frameIndex = 1:numFrames
    interpolatedFrames(:,:,frameIndex) = interpolateFrame(refFrames(:,:,frameIndex), blockSize);
end
end

function interpolatedFrame = interpolateFrame(refFrame, blockSize)
% Determine the dimensions of the original block
[height, width] = size(refFrame);

% Initialize the matrix for the interpolated reference block
interpolatedBlockHeight = 2*height-2*blockSize+1;
interpolatedBlockWidth = 2*width-2*blockSize+1;

interpolatedHeight = interpolatedBlockHeight*blockSize;
interpolatedWidth = interpolatedBlockWidth*blockSize;
interpolatedFrame = zeros(interpolatedHeight, interpolatedWidth);

for i = 1:height-blockSize+1
    for j = 1:width-blockSize+1
        heightPixelIndex = (i-1)*blockSize*2+1;
        widthPixelIndex = (j-1)*blockSize*2+1;
        interpolatedFrame(heightPixelIndex:heightPixelIndex+blockSize-1,widthPixelIndex:widthPixelIndex+blockSize-1) = refFrame(i:i+blockSize-1,j:j+blockSize-1);
    end
end

for i = 1:2:interpolatedBlockHeight
    for j = 2:2:interpolatedBlockWidth
        heightPixelIndex = (i-1)*blockSize+1;
        widthPixelIndex = (j-1)*blockSize+1;
        interpolatedFrame(heightPixelIndex, widthPixelIndex) = round((interpolatedFrame(heightPixelIndex, widthPixelIndex-blockSize)+interpolatedFrame(heightPixelIndex, widthPixelIndex+blockSize))/2,0);
        interpolatedFrame(heightPixelIndex, widthPixelIndex+1) = round((interpolatedFrame(heightPixelIndex, widthPixelIndex+1-blockSize)+interpolatedFrame(heightPixelIndex, widthPixelIndex+1+blockSize))/2,0);
        interpolatedFrame(heightPixelIndex+1, widthPixelIndex) = round((interpolatedFrame(heightPixelIndex+1, widthPixelIndex-blockSize)+interpolatedFrame(heightPixelIndex+1, widthPixelIndex+blockSize))/2,0);
        interpolatedFrame(heightPixelIndex+1, widthPixelIndex+1) = round((interpolatedFrame(heightPixelIndex+1, widthPixelIndex+1-blockSize)+interpolatedFrame(heightPixelIndex+1, widthPixelIndex+1+blockSize))/2,0);
    end
end

for j = 1:2:interpolatedBlockWidth
    for i = 2:2:interpolatedBlockHeight
        heightPixelIndex = (i-1)*blockSize+1;
        widthPixelIndex = (j-1)*blockSize+1;
        interpolatedFrame(heightPixelIndex, widthPixelIndex) = round((interpolatedFrame(heightPixelIndex-blockSize, widthPixelIndex)...
                                                                     +interpolatedFrame(heightPixelIndex+blockSize, widthPixelIndex))...
                                                                     /2,0);
        interpolatedFrame(heightPixelIndex, widthPixelIndex+1) = round((interpolatedFrame(heightPixelIndex-blockSize, widthPixelIndex+1)...
                                                                       +interpolatedFrame(heightPixelIndex+blockSize, widthPixelIndex+1))...
                                                                       /2,0);
        interpolatedFrame(heightPixelIndex+1, widthPixelIndex) = round((interpolatedFrame(heightPixelIndex+1-blockSize, widthPixelIndex)...
                                                                       +interpolatedFrame(heightPixelIndex+1+blockSize, widthPixelIndex))...
                                                                       /2,0);
        interpolatedFrame(heightPixelIndex+1, widthPixelIndex+1) = round((interpolatedFrame(heightPixelIndex+1-blockSize, widthPixelIndex+1)...
                                                                         +interpolatedFrame(heightPixelIndex+1+blockSize, widthPixelIndex+1))...
                                                                         /2,0);
    end
end

for j = 2:2:interpolatedBlockWidth
    for i = 2:2:interpolatedBlockHeight
        heightPixelIndex = (i-1)*blockSize+1;
        widthPixelIndex = (j-1)*blockSize+1;
        interpolatedFrame(heightPixelIndex, widthPixelIndex) = round((interpolatedFrame(heightPixelIndex-blockSize, widthPixelIndex)...
                                                                     +interpolatedFrame(heightPixelIndex+blockSize, widthPixelIndex)...
                                                                     +interpolatedFrame(heightPixelIndex, widthPixelIndex-blockSize)...
                                                                     +interpolatedFrame(heightPixelIndex, widthPixelIndex+blockSize))...
                                                                     /4,0);
        interpolatedFrame(heightPixelIndex, widthPixelIndex+1) = round((interpolatedFrame(heightPixelIndex-blockSize, widthPixelIndex+1)...
                                                                     +interpolatedFrame(heightPixelIndex+blockSize, widthPixelIndex+1)...
                                                                     +interpolatedFrame(heightPixelIndex, widthPixelIndex-blockSize+1)...
                                                                     +interpolatedFrame(heightPixelIndex, widthPixelIndex+blockSize+1))...
                                                                     /4,0);
        interpolatedFrame(heightPixelIndex+1, widthPixelIndex) = round((interpolatedFrame(heightPixelIndex+1-blockSize, widthPixelIndex)...
                                                                     +interpolatedFrame(heightPixelIndex+1+blockSize, widthPixelIndex)...
                                                                     +interpolatedFrame(heightPixelIndex+1, widthPixelIndex-blockSize)...
                                                                     +interpolatedFrame(heightPixelIndex+1, widthPixelIndex+blockSize))...
                                                                     /4,0);
        interpolatedFrame(heightPixelIndex+1, widthPixelIndex+1) = round((interpolatedFrame(heightPixelIndex+1-blockSize, widthPixelIndex+1)...
                                                                     +interpolatedFrame(heightPixelIndex+1+blockSize, widthPixelIndex+1)...
                                                                     +interpolatedFrame(heightPixelIndex+1, widthPixelIndex-blockSize+1)...
                                                                     +interpolatedFrame(heightPixelIndex+1, widthPixelIndex+blockSize+1))...
                                                                     /4,0);
    end
end

end

