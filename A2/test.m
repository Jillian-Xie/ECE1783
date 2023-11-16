interpolatedRefFrames = [25    27    28    29    29
    38    41    43    42    41
    50    54    57    55    53
    47    51    55    55    55
    44    48    52    54    56];

currentFrame = [29 25 28; 53 50 57; 56 44 52];
widthPixelIndex = 1;
heightPixelIndex = 1;
blockSize = 2;
r = 2;

[bestMV, bestMAE, referenceBlock, residualBlock] = fractionalPixelFullSearch(interpolatedRefFrames, currentFrame, widthPixelIndex, heightPixelIndex, blockSize, r)