function [encodedQuantizedBlock, quantizedBlock] = dctQuantizeAndEncode(residualBlock, QP, blockSize)
    transformedBlock = dct2(residualBlock);
    quantizedBlock = quantize(transformedBlock, QP);
    
    scanned = scanBlock(quantizedBlock, blockSize);
    encodedRLE = RLE(scanned);
    encodedQuantizedBlock = expGolombEncoding(encodedRLE);
end