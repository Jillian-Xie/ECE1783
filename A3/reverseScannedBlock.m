function block = reverseScannedBlock(scanned, blockSize)
    % array is assumed to be size 1x(blockSize * blockSize)
    % retrun an matrix of size blockSize x blockSize
    
    block = int32(zeros(blockSize, blockSize));

    currentWidthIndex = 1;
    currentHeightIndex = 1;
    processedWidthIndex = 1;
    processedHeightIndex = 1;
    for scannedIndex = 1 : blockSize * blockSize
        block(currentHeightIndex, currentWidthIndex) = scanned(1, scannedIndex);
        
        if currentWidthIndex == 1 || currentHeightIndex == blockSize
            % we've reached the left boundary
            currentWidthIndex = processedWidthIndex + 1;
            currentHeightIndex = 1;
            
            processedWidthIndex = processedWidthIndex + 1;
            
            if currentWidthIndex > blockSize
                currentWidthIndex = blockSize;
                currentHeightIndex = processedHeightIndex + 1;

                processedHeightIndex = processedHeightIndex + 1;
            end
        else
            currentWidthIndex = currentWidthIndex - 1;
            currentHeightIndex = currentHeightIndex + 1;
        end
    end
end