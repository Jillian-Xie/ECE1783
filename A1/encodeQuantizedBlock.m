function encodedQuantizedBlock = encodeQuantizedBlock(quantizedBlock, blockSize)
    scanned = scanBlock(quantizedBlock, blockSize);
    encodedRLE = RLE(scanned);
end