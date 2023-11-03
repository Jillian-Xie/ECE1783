function scanned = scanBlock(block, blockSize)
    % block is assumed to be blockSize * blockSize
    % return an array of size 1x(blockSize * blockSize)
    
    scanned = int32(zeros(1, blockSize * blockSize));

    currentWidthIndex = 1;
    currentHeightIndex = 1;
    processedWidthIndex = 1;
    processedHeightIndex = 1;
    for scannedIndex = 1 : blockSize * blockSize
        scanned(1, scannedIndex) = block(currentHeightIndex, currentWidthIndex);
        
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