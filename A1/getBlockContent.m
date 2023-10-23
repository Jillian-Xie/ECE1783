function blockContent = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, frame, widthOffset, heightOffset)
    widthStart = int32((widthBlockIndex-1)*blockSize + 1 + widthOffset);
    widthEnd = int32(widthStart + blockSize - 1);
    heightStart = int32((heightBlockIndex-1)*blockSize + 1 + heightOffset);
    heightEnd = int32(heightStart + blockSize - 1);
    blockContent = frame(heightStart:heightEnd, widthStart:widthEnd);