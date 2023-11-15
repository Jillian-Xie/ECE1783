function interpolatedFrames = interpolateFrames(refFrames, blockSize)
    % Determine the size of the interpolated frames
    [height, width, numFrames] = size(refFrames);
    interpolatedHeight = height * 2;
    interpolatedWidth = width * 2;

    % Initialize the interpolated frames
    interpolatedFrames = zeros(interpolatedHeight, interpolatedWidth, numFrames);

    % Perform interpolation for each reference frame
    for frameIndex = 1:numFrames
        interpolatedFrames(:,:,frameIndex) = imresize(refFrames(:,:,frameIndex), [interpolatedHeight, interpolatedWidth], 'bilinear');
    end
end

%function interpolatedRefBlock = interpolateFrames(refBlockExample, blockSize)
%    % Determine the dimensions of the original block
%    [origHeight, origWidth] = size(refBlockExample);
%    
%    % Initialize the matrix for the interpolated reference block
%    % The new size will be twice as large as the original to include interpolated pixels
%    interpolatedHeight = origHeight * 2 - 1;
%    interpolatedWidth = origWidth * 2 - 1;
%    interpolatedRefBlock = zeros(interpolatedHeight, interpolatedWidth);
%    
%    % Copy the original reference block values into the interpolated block
%    interpolatedRefBlock(1:2:end, 1:2:end) = refBlockExample;
%    
%    % Interpolate horizontally and vertically
%    for i = 1:2:interpolatedHeight
%        for j = 1:2:interpolatedWidth
%            % Horizontal interpolation
%            if j+2 <= interpolatedWidth
%                interpolatedRefBlock(i, j+1) = (interpolatedRefBlock(i, j) + interpolatedRefBlock(i, j+2)) / 2;
%            end
%            % Vertical interpolation
%            if i+2 <= interpolatedHeight
%                interpolatedRefBlock(i+1, j) = (interpolatedRefBlock(i, j) + interpolatedRefBlock(i+2, j)) / 2;
%            end
%        end
%    end
%    
%    % Diagonal interpolation
%    for i = 2:2:interpolatedHeight-1
%        for j = 2:2:interpolatedWidth-1
%            interpolatedRefBlock(i, j) = (interpolatedRefBlock(i-1, j-1) + interpolatedRefBlock(i-1, j+1) ...
%                                        + interpolatedRefBlock(i+1, j-1) + interpolatedRefBlock(i+1, j+1)) / 4;
%        end
%    end
%end

