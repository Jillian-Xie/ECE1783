classdef reconstructedFrame
    %reconstructedFrame Summary of this class goes here
    properties
        referenceFrames;
        motionVector;
        residual;
        nRefFrames;
        VBSEnable;
        FMEEnable;
    end

    methods
        function obj = reconstructedFrame(referenceFrames, mv, residual, nRefFrames, VBSEnable, FMEEnable)
            obj.referenceFrames = referenceFrames;
            obj.motionVector = mv;
            obj.residual = residual;
            obj.nRefFrames = nRefFrames;
            obj.VBSEnable = VBSEnable;
            obj.FMEEnable = FMEEnable;
        end

        function [colorReconstructed, reconstructed] = reconstruct(obj)
            colorReconstructed = {};
            reconstructBlocks = {};
            blockSize = size(obj.residual, 1) / size(obj.motionVector, 1);
            s = size(obj.residual);
            if obj.nRefFrames > 1
                mvLen = 3;
            else
                mvLen = 2;
            end
            for x = 1 : s(1) / blockSize
                for y = 1 : s(2) / blockSize
                    approximated = obj.residual(1 + (x - 1) * blockSize : x * blockSize, 1 + (y - 1) * blockSize : y * blockSize);
                    mvX = obj.motionVector(x, mvLen * (y - 1) + 1);
                    mvY = obj.motionVector(x, mvLen * (y - 1) + 2);
                    if obj.nRefFrames > 1
                        mvF = obj.motionVector(x, mvLen * y);
                    else
                        mvF = 0;
                    end
                    [colored, block] = obj.getReconstructedBlock(blockSize, x, y, approximated, mvX, mvY, mvF);
                    colorReconstructed{x, y} = colored;
                    reconstructBlocks{x, y} = block;
                end
            end
            colorReconstructed = cell2mat(colorReconstructed);
            reconstructed = cell2mat(reconstructBlocks);
        end

        function [colorRB, recontructedBlock] = getReconstructedBlock(obj, blockSize, x, y, approximated, mvX, mvY, mvF)
            if obj.FMEEnable
                if (rem(mvX, 2) == 0 && rem(mvY, 2) == 0)
                    predictedX = 1 + (x - 1) * blockSize + mvX/2;
                    predictedY = 1 + (y - 1) * blockSize - mvY/2;
                    predictedFrame = obj.referenceFrames{length(obj.referenceFrames) - mvF}.frameData;
                    predicted = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                elseif (rem(mvX, 2) ~= 0 && rem(mvY, 2) == 0)
                    predictedX = 1 + (x - 1) * blockSize + (mvX+1)/2;
                    predictedY = 1 + (y - 1) * blockSize - mvY/2;
                    predictedFrame = obj.referenceFrames{length(obj.referenceFrames) - mvF}.frameData;
                    predictedA = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                    predictedX = 1 + (x - 1) * blockSize + (mvX-1)/2;
                    predictedY = 1 + (y - 1) * blockSize - mvY/2;
                    predictedB = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                    predicted = obj.newdata(predictedA, predictedB);
                elseif (rem(mvX, 2) == 0 && rem(mvY, 2) ~= 0)
                    predictedX = 1 + (x - 1) * blockSize + mvX/2;
                    predictedY = 1 + (y - 1) * blockSize - (mvY+1)/2;
                    predictedFrame = obj.referenceFrames{length(obj.referenceFrames) - mvF}.frameData;
                    predictedA = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                    predictedX = 1 + (x - 1) * blockSize + mvX/2;
                    predictedY = 1 + (y - 1) * blockSize - (mvY-1)/2;
                    predictedB = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                    predicted = obj.newdata(predictedA, predictedB);
                else
                    predictedX = 1 + (x - 1) * blockSize + (mvX+1)/2;
                    predictedY = 1 + (y - 1) * blockSize - (mvY+1)/2;
                    predictedFrame = obj.referenceFrames{length(obj.referenceFrames) - mvF}.frameData;
                    predictedA = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                    predictedX = 1 + (x - 1) * blockSize + (mvX+1)/2;
                    predictedY = 1 + (y - 1) * blockSize - (mvY-1)/2;
                    predictedB = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                    predictedX = 1 + (x - 1) * blockSize + (mvX-1)/2;
                    predictedY = 1 + (y - 1) * blockSize - (mvY+1)/2;
                    predictedC = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                    predictedX = 1 + (x - 1) * blockSize + (mvX-1)/2;
                    predictedY = 1 + (y - 1) * blockSize - (mvY-1)/2;
                    predictedD = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
                    predictedAB = obj.newdata(predictedA, predictedB);
                    predictedABC = obj.newdata(predictedAB, predictedC);
                    predicted = obj.newdata(predictedABC, predictedD);
                end
            else
                predictedX = 1 + (x - 1) * blockSize + mvX;
                predictedY = 1 + (y - 1) * blockSize - mvY;
                predictedFrame = obj.referenceFrames{length(obj.referenceFrames) - mvF}.frameData;
                predicted = predictedFrame(predictedX : predictedX + blockSize - 1, predictedY : predictedY + blockSize - 1);
            end
            recontructedBlock = uint8(double(predicted) + double(approximated));

            % add Color to Block
            colorRB = repmat(recontructedBlock, 1, 1, 3);

            if obj.nRefFrames > 1
                if mvF ~= 0
                    colorRB(:, :, mvF) = 255;
                end
            end

            if obj.VBSEnable == 1
                % add block boundary
                colorRB(1, :, :) = 0;
                colorRB(:, 1, :) = 0;
                colorRB(blockSize, :, :) = 0;
                colorRB(:, blockSize, :) = 0;
            end
        end

        function newdata = newdata(obj, dataA, dataB)
            sizeofblock = size(dataA);
            newdata = zeros(sizeofblock(1), sizeofblock(2));
            for x = 1:sizeofblock(1)
                for y = 1:sizeofblock(2)
                    newdata(x,y) = round((uint16(dataA(x,y)) + uint16(dataB(x,y)))/2);
                end
            end
        end
    end

end