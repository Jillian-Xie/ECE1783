classdef rcDecoder
    %rcEncoder Summary of this class goes here
    properties
        outputFolder
    end

    methods
        function obj = rcDecoder(outputFolder)
            obj.outputFolder = outputFolder;
        end

        function output = decode(obj)
            mvPath = obj.outputFolder + "motionVectors.txt";
            residualPath = obj.outputFolder + "residual.txt";

            mvFid = fopen(mvPath, 'r');
            residualFid = fopen(residualPath, 'r');

            params = fgetl(residualFid);
            params = entropy(params, 0).decode(0);
            params = num2cell(params);

            if length(params) ~= 5
                en = decoder(obj.outputFolder);
                en.decode();
            else
                [width, height, nframes, QP, RCflag] = deal(params{:});
                i = 16;

                paddingWidth = ceil(width / i) * i;
                paddingHeight = ceil(height / i) * i;

                numBlockWidth = paddingWidth / i;
                numBlockHeight = paddingHeight / i;

                referenceFrames = {};
                referenceFrames{1} = frameBlocks(uint8(128 * ones(height, width)), i);
                prevQPs = ones(1, ceil(height / i)) * 4;

                for f = 1 : nframes
                    mvLen = 2;

                    marker = entropy(fgetl(mvFid), i).decode(0);
                    splitStr = fgetl(mvFid);

                    motionVectors = reshape(split(strtrim(fgetl(mvFid)), ' '), numBlockHeight, numBlockWidth);
                    residuals = reshape(split(strtrim(fgetl(residualFid)), ' '), numBlockHeight, numBlockWidth);
                    vf = vbsFrame(referenceFrames, splitStr, motionVectors, residuals, width, height, i, QP, 1, 1, 1);
                    [colorReconstructed, referenceFrame, QPs] = vf.reconstructedFrameWithQP(prevQPs);
                    prevQPs = QPs;

                    subplot(ceil(nframes / 7), 7, f), imshow(referenceFrame(1 : height, 1 : width));
                    if marker == 1
                        modes = strtrim(fgetl(mvFid));
                        intra = vbsIntraFrame(referenceFrame, width, height, i, 1, splitStr);
                        referenceFrame = intra.getPredictedVBS(modes);
                        referenceFrames = {};
                    end

                    referenceFrames{length(referenceFrames) + 1} = frameBlocks(referenceFrame, i);
                    if length(referenceFrames) > 1
                        referenceFrames(1) = [];
                    end
                end
            end

            fclose('all');
        end
    end

end