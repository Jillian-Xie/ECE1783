function encodedQuantizedBlock = encodeQuantizedBlock(quantizedBlock, blockSize)
    scanned = scanBlock(quantizedBlock, blockSize);
    encodedRLE = RLE(scanned);
    encodedQuantizedBlock = expGolombEncoding(encodedRLE);
end