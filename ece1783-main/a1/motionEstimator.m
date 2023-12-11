classdef motionEstimator
    %motionEstimator Summary of this class goes here
    properties
        yFrames;
        referenceFrames;
        i;
        QP;
        isDifferential;
        isEntropy;
        nRefFrames;
        VBSEnable;
        j;
        FMEEnable;
    end

    methods
        function obj = motionEstimator(yFrames, i, QP, isDifferential, isEntropy, nRefFrames, VBSEnable, j, FMEEnable)
            obj.yFrames = yFrames;
            obj.referenceFrames = {};
            obj.i = i;
            obj.QP = QP;
            obj.isDifferential = isDifferential;
            obj.isEntropy = isEntropy;
            obj.nRefFrames = nRefFrames;
            obj.VBSEnable = VBSEnable;
            obj.j = j;
            obj.FMEEnable = FMEEnable;
        end

        function obj = addReferenceFrame(obj, frameData)
            frame = frameBlocks(frameData, obj.i);
            obj.referenceFrames{length(obj.referenceFrames) + 1} = frame;
            if length(obj.referenceFrames) > obj.nRefFrames
                obj.referenceFrames(1) = [];
            end
        end

        function obj = clearReferenceFrames(obj)
            obj.referenceFrames = {};
        end

        function fme = getRCFrameMotionEstimator(obj, frameNumber)
            currFrame = frameBlocks(obj.yFrames(:, :, frameNumber), obj.i);
            fme = VBSMotionEstimator(currFrame, obj.referenceFrames, 1, obj.i, obj.j, obj.QP, 1, 1);
        end

        function fme = getFrameMotionEstimator(obj, frameNumber)
            currFrame = frameBlocks(obj.yFrames(:, :, frameNumber), obj.i);
            if obj.VBSEnable == 1
                fme = VBSMotionEstimator(currFrame, obj.referenceFrames, obj.nRefFrames, obj.i, obj.j, obj.QP, obj.isDifferential, obj.FMEEnable);
            elseif obj.FMEEnable == 1
                fme = fractionalMotionEstimation(currFrame, obj.referenceFrames, obj.nRefFrames);
            elseif obj.QP >= 0
                fme = quantizedMotionEstimator(currFrame, obj.referenceFrames, obj.nRefFrames);
            else
                fme = frameMotionEstimator(currFrame, obj.referenceFrames, obj.nRefFrames);
            end
        end

        function differential = getDifferential(obj, mode, data)
            if obj.isDifferential == 1
                differential = differentialCode(mode, obj.nRefFrames).encode(data);
            else
                differential = data;
            end
        end

        function entropyed = getEntropy(obj, mode, data)
            if obj.isEntropy
                entropyed = entropy(data, obj.i).encode(mode, 0);
            elseif mode == 0
                if iscell(data)
                    data = cell2mat(data);
                end
                entropyed = sprintf("%d ", data);
            else
                entropyed = data;
            end

        end
    end
end