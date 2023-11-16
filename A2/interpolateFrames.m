function interpolatedFrames = interpolateFrames(refFrames)
% Determine the size of the interpolated frames
[height, width, numFrames] = size(refFrames);
interpolatedHeight = 2*height-1;
interpolatedWidth = 2*width-1;

% Initialize the interpolated frames
interpolatedFrames = zeros(interpolatedHeight, interpolatedWidth, numFrames);

% Perform interpolation for each reference frame
for frameIndex = 1:numFrames
    interpolatedFrames(:,:,frameIndex) = interpolateFrame(refFrames(:,:,frameIndex));
end
end

function interpolatedFrame = interpolateFrame(refFrame)
% Determine the dimensions of the original block
[height, width] = size(refFrame);

interpolatedHeight = 2*height-1;
interpolatedWidth = 2*width-1;
interpolatedFrame = zeros(interpolatedHeight, interpolatedWidth);

for i = 1:height
    for j = 1:width
        heightPixelIndex = (i-1)*2+1;
        widthPixelIndex = (j-1)*2+1;
        interpolatedFrame(heightPixelIndex,widthPixelIndex) = refFrame(i,j);
    end
end

for i = 1:2:interpolatedHeight
    for j = 2:2:interpolatedWidth
        interpolatedFrame(i, j) = round((interpolatedFrame(i, j+1)+interpolatedFrame(i, j-1))/2,0);
    end
end

for j = 1:2:interpolatedWidth
    for i = 2:2:interpolatedHeight
        interpolatedFrame(i, j) = round((interpolatedFrame(i+1, j)+interpolatedFrame(i-1, j))/2,0);
    end
end

for j = 2:2:interpolatedWidth
    for i = 2:2:interpolatedHeight
        interpolatedFrame(i, j) = round((interpolatedFrame(i-1, j)...
                                        +interpolatedFrame(i, j-1)...
                                        +interpolatedFrame(i+1, j)...
                                        +interpolatedFrame(i, j+1)...
                                         )/4,0);
    end
end

end

