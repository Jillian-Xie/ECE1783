function rescaledBlock = rescaling(quantizedBlock, QP)
blockWidth = size(quantizedBlock,1);
blockHeight = size(quantizedBlock,2);

QMatrix(1:blockWidth, 1:blockHeight) = int32(0);
rescaledBlock(1:blockWidth, 1:blockHeight) = int32(0);

for x=1:blockWidth
    for y=1:blockHeight
        if (x + y - 2 < blockHeight - 1)
            QMatrix(x,y) = power(2, QP);
        elseif(x + y - 2 == blockHeight - 1)
            QMatrix(x,y) = power(2, QP + 1);
        else
            QMatrix(x,y) = power(2, QP + 2);
        end
    end
end

for x=1:blockWidth
    for y=1:blockHeight
        rescaledBlock(x,y) = round(quantizedBlock(x,y) * QMatrix(x,y));
    end
end


