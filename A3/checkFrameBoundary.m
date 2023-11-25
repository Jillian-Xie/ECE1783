function flag = checkFrameBoundary(widthStart, heightStart, blockSize, frame)
height = int32(size(frame, 1));
width = int32(size(frame, 2));
widthEnd = int32(widthStart + blockSize - 1);
heightEnd = int32(heightStart + blockSize - 1);
if widthStart >= 1 && widthEnd <= width && heightStart >= 1 && heightEnd <= height
    flag = 1;
else
    flag = 0;
end

