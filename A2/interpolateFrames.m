function interpolatedFrames = interpolateFrames(refFrames, blockSize)
    % Determine the size of the interpolated frames
    [height, width, numFrames] = size(refFrames);
    interpolatedHeight = height * 2;
    interpolatedWidth = width * 2;

    % Initialize the interpolated frames
    interpolatedFrames = zeros(interpolatedHeight, interpolatedWidth, numFrames);

    % Perform interpolation for each reference frame
    for frameIndex = 1:numFrames
        interpolatedFrames(:,:,frameIndex) = interpolateFrame(refFrames(:,:,frameIndex), blockSize);
    end
end

function interpolatedFrame = interpolateFrame(refBlockExample, blockSize)
   % Determine the dimensions of the original block
   [origHeight, origWidth] = size(refBlockExample);

   % Initialize the matrix for the interpolated reference block
   % The new size will be twice as large as the original to include interpolated pixels
   interpolatedHeight = origHeight * 2;
   interpolatedWidth = origWidth * 2;
   interpolatedFrame = zeros(interpolatedHeight, interpolatedWidth);

   for i = 1:origHeight
       for j = 1:origWidth
           interpolatedFrame(2*i)
       end
   end

   
end

