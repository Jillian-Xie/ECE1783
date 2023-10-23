function quantizedtransformedBlock = quantize(transformedCoefficientBlock, QP)
blockHeight = size(transformedCoefficientBlock,1);
blockWidth = size(transformedCoefficientBlock,2);

QMatrix(1:blockHeight, 1:blockWidth) = int32(0);
quantizedtransformedBlock(1:blockHeight, 1:blockWidth) = int32(0);

for x=1:blockHeight
    for y=1:blockWidth
        if (x + y - 2 < blockHeight - 1)
            QMatrix(x,y) = power(2, QP);
        elseif(x + y - 2 == blockHeight - 1)
            QMatrix(x,y) = power(2, QP + 1);
        else
            QMatrix(x,y) = power(2, QP + 2);
        end
    end
end

for x=1:blockHeight
    for y=1:blockWidth
        quantizedtransformedBlock(x,y) = round(transformedCoefficientBlock(x,y)/QMatrix(x,y));
    end
end


