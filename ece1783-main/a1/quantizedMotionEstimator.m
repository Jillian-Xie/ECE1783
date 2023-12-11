classdef quantizedMotionEstimator < frameMotionEstimator
   methods
    function dctTransformed = getDCTBlocks(obj, residuals)
        % use dct2 from image processing toolbox and round
        s = size(residuals);
        dctTransformed = {};
        for x = 1 : s(1)
            for y = 1 : s(2)
                dctTransformed{x, y} = round(dct2(cell2mat(residuals(x, y))));
            end
        end
    end

    function dctTransformed = getDCTBlocksPerRow(obj, residuals, x, rowCount)
        % use dct2 from image processing toolbox and round
        s = size(residuals);
        dctTransformed = {};
        for x = 1 : s(1)
            for y = 1 : s(2)
                dctTransformed{x, y} = round(dct2(cell2mat(residuals(x, y))));
            end
        end
    end

    function QTCs = getQuatizedBlocks(obj, TC, QP)
        % build QTC according to QP
        s = size(TC);
        QTCs = {};
        for x = 1 : s(1)
            for y = 1 : s(2)
                QTCs{x, y} = obj.getQuatizedBlock(cell2mat(TC(x, y)), QP);
            end
        end
    end

    function QTC = getQuatizedBlock(obj, transformed, QP)
        blockSize = size(transformed, 1);
        QTC = ones(blockSize, blockSize);
        for x = 1 : blockSize
            for y = 1 : blockSize
                if obj.isValidQP(QP, blockSize)
                    QTC(x, y) = round(transformed(x, y) / obj.getQ(QP, x, y, blockSize));
                end
            end
        end
    end

    function Q = getQ(obj, QP, x, y, blockSize)
        if x + y < blockSize - 1
            Q = pow2(QP);
        elseif x + y == blockSize - 1
            Q = pow2(QP + 1);
        else
            Q = pow2(QP + 2);
        end
    end

    function isValid = isValidQP(obj, QP, blockSize)
        if QP < 0
            isValid = false;
        elseif QP > log2(double(blockSize)) + 7
            isValid = false;
        else
            isValid = true;
        end
    end
   end
end