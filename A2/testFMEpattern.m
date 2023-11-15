% Example reference block (3x3 region from assignment)
refBlockExample = [25, 28, 29;
                   50, 57, 53;
                   44, 52, 56];

% Example current block (2x2 co-located block from assignment)
currentBlockExample = [40, 42;
                       50, 56];


% Size of the block
blockSize = 2;

% Interpolate the reference block
interpolatedRefBlock = interpolateFrames(refBlockExample, blockSize);
disp(interpolatedRefBlock(1:4, 1:4, 1));

% We need to define the starting pixel index for the current block
% For simplicity, let's say it's the first pixel of the interpolated block
widthPixelIndex = 1;
heightPixelIndex = 1;

% Search range (r), assuming it's the same as in the assignment
r = 1;

% Perform fractional pixel full search
% Note: Your fractionalPixelFullSearch function needs to handle the case
% where the search position is out of the block boundary.
[bestMV, bestMAE, referenceBlock, residualBlock] = fractionalPixelFullSearch(interpolatedRefBlock, currentBlockExample, widthPixelIndex, heightPixelIndex, blockSize, r);

% Output the results
disp('Best Motion Vector (MV):');
disp(bestMV);
disp('Best Mean Absolute Error (MAE):');
disp(bestMAE);
disp('Reference Block:');
disp(referenceBlock);
disp('Residual Block:');
disp(residualBlock);
