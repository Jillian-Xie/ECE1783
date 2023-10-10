function flag = checkFrameBoundary(x, y, blockSize, frame)
widthBlockNum = idivide(uint32(size(frame, 1)), uint32(blockSize), 'ceil');
heightBlockNum = idivide(uint32(size(frame, 2)), uint32(blockSize), 'ceil');
if x >= 1 && x <= widthBlockNum && y >= 1 && y <= heightBlockNum
    flag = 1;
else
    flag = 0;
end

