function [verticalRefernce, horizontalReference] = getIntraPredictionReference(heightBlockIndex, widthBlockIndex, reconstructedFrame, blockSize)
verticalRefernce(1:1,1:blockSize) = int32(128);
horizontalReference(1:blockSize,1:1) = int32(128);

widthStart = int32((widthBlockIndex-1)*blockSize + 1);
widthEnd = int32(widthStart + blockSize - 1);
heightStart = int32((heightBlockIndex-1)*blockSize + 1);
heightEnd = int32(heightStart + blockSize - 1);

if (heightBlockIndex > 1)
    verticalRefernce = reconstructedFrame(heightStart-1, widthStart:widthEnd);
end
if (widthBlockIndex > 1)
    horizontalReference = reconstructedFrame(heightStart:heightEnd, widthStart-1);
end
end