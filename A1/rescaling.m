function rescaledBlock = rescaling(quantizedBlock, QP)
blockHeight = size(quantizedBlock,1);
blockWidth = size(quantizedBlock,2);

QMatrix(1:blockHeight, 1:blockWidth) = int32(0);
rescaledBlock(1:blockHeight, 1:blockWidth) = int32(0);

% init QMatrix
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

% Rescale
for x=1:blockHeight
    for y=1:blockWidth
        rescaledBlock(x,y) = round(quantizedBlock(x,y) * QMatrix(x,y));
    end
end


