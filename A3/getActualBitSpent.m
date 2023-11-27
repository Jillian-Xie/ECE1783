function actualBitSpent = getActualBitSpent(QTCCoeffsFrame, MDiffsInt, splitInt, QPInt)

MDiffRLE = RLE(MDiffsInt);
MDiffsFrame = expGolombEncoding(MDiffRLE);

splitsRLE = RLE(splitInt);
splitsFrame = expGolombEncoding(splitsRLE);

QPRLE = RLE(QPInt);
QPFrame = expGolombEncoding(QPRLE);

actualBitSpent = sum(strlength(QTCCoeffsFrame), "all") + ...
            sum(strlength(MDiffsFrame), "all") + ...
            sum(strlength(splitsFrame), "all") + ...
            sum(strlength(QPFrame), "all");

end

