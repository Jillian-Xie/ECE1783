function blockContent = getBlockContent(widthBlockIndex, heightBlockIndex, blockSize, frame)
    widthStart = int32((widthBlockIndex-1)*blockSize + 1);
    widthEnd = int32(widthStart + blockSize - 1);
    heightStart = int32((heightBlockIndex-1)*blockSize + 1);
    heightEnd = int32(heightStart + blockSize - 1);
    blockContent = frame(widthStart:widthEnd, heightStart:heightEnd);