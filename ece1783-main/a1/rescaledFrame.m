classdef rescaledFrame
    %rescaledFrame Summary of this class goes here
    properties
        residual;
        blockSize;
        QP;
    end

    methods
        function obj = rescaledFrame(residual, blockSize, QP)
            obj.residual = residual;
            obj.blockSize = blockSize;
            obj.QP = QP;
        end

        function residuals = rescaled(obj)
            rescaledBlocks = obj.getRescaledBlocks(obj.residual, obj.QP);
            residuals = obj.getIDCTBlocks(rescaledBlocks);
        end

        function idctResiduals = getIDCTBlocks(obj, dctTransformed)
            s = size(dctTransformed);
            idctResiduals = {};
            for x = 1 : s(1)
                for y = 1 : s(2)
                    idctResiduals{x, y} = round(idct2(cell2mat(dctTransformed(x, y))));
                end
            end
        end

        function rescaledBlocks = getRescaledBlocks(obj, QTC, QP)

            s = size(QTC);
            rescaledBlocks = {};
            for x = 1 : s(1)
                for y = 1 : s(2)
                    rescaledBlocks{x, y} = obj.getRescaledBlock(cell2mat(QTC(x, y)), QP);
                end
            end
        end

        function rescaled = getRescaledBlock(obj, transformed, QP)
            rescaled = ones(obj.blockSize, obj.blockSize);
            for x = 1 : obj.blockSize
                for y = 1 : obj.blockSize
                    rescaled(x, y) =  transformed(x, y) * obj.getQ(QP, x, y);
                end
            end
        end

        function Q = getQ(obj, QP, x, y)
            if x + y < obj.blockSize - 1
                Q = pow2(QP);
            elseif x + y == obj.blockSize - 1
                Q = pow2(QP + 1);
            else
                Q = pow2(QP + 2);
            end
        end
    end

end