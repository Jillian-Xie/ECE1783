classdef decoder
    %decoder Summary of this class goes here
    properties
        outputFolder;
    end

    methods
        function obj = decoder(outputFolder)
            obj.outputFolder = outputFolder;
        end

        function decoded = decode(obj)
            mvPath = obj.outputFolder + "motionVectors.txt";
            residualPath = obj.outputFolder + "residual.txt";

            mvFid = fopen(mvPath, 'r');
            residualFid = fopen(residualPath, 'r');

            params = fgetl(residualFid);
            if all(ismember(params, '01'))
                params = entropy(params, 0).decode(0);
            else
                params = str2num(params);
            end
            params = num2cell(params);
            [width, height, nframes, nRefFrames, i, QP, isDifferential, isEntropy, VBSEnable, FMEEnable] = deal(params{:});

            paddingWidth = ceil(width / i) * i;
            paddingHeight = ceil(height / i) * i;

            numBlockWidth = paddingWidth / i;
            numBlockHeight = paddingHeight / i;

            referenceFrames = {};
            referenceFrames{1} = frameBlocks(uint8(128 * ones(height, width)), i);

            for f = 1 : nframes
                if nRefFrames > 1
                    mvLen = 3;
                else
                    mvLen = 2;
                end

                if VBSEnable == 1
                    marker = entropy(fgetl(mvFid), i).decode(0);
                    splitStr = fgetl(mvFid);

                    motionVectors = reshape(split(strtrim(fgetl(mvFid)), ' '), numBlockHeight, numBlockWidth);
                    residuals = reshape(split(strtrim(fgetl(residualFid)), ' '), numBlockHeight, numBlockWidth);
                    vf = vbsFrame(referenceFrames, splitStr, motionVectors, residuals, width, height, i, QP, isDifferential, nRefFrames, FMEEnable);
                    [colorReconstructed, referenceFrame] = vf.reconstructedFrame();

                    if marker == 1
                        modes = strtrim(fgetl(mvFid));
                        intra = vbsIntraFrame(referenceFrame, width, height, i, isDifferential, splitStr);
                        referenceFrame = intra.getPredictedVBS(modes);
                        referenceFrames = {};
                    end
                else
                    if isEntropy
                        marker = entropy(fgetl(mvFid), i).decode(0);
                        mv = reshape(entropy(fgetl(mvFid), i).decode(0), numBlockHeight, numBlockWidth * mvLen);
                        residualLine = entropy(fgetl(residualFid), i).decode(0);
                    else
                        marker = str2num(fgetl(mvFid));
                        mv = reshape(str2num(fgetl(mvFid)), numBlockHeight, numBlockWidth * mvLen);
                        residualLine = str2num(fgetl(residualFid));
                    end
                    if isDifferential == 1
                        mv = differentialCode(0, nRefFrames).decode(mv);
                    end

                    if isEntropy
                        residualBlocks = entropy(residualLine, i).decode(1, numBlockHeight);
                    else
                        residual = reshape(residualLine, paddingHeight, paddingWidth);
                        residualBlocks = mat2cell(residual, i * int32(ones(1, numBlockHeight)), i * int32(ones(1, numBlockWidth)));
                    end

                    if QP >= 0
                        residual = cell2mat(rescaledFrame(residualBlocks, i, QP).rescaled());
                    else
                        residual = cell2mat(residualBlocks);
                    end

                    reconstructed = reconstructedFrame(referenceFrames, mv, residual, nRefFrames, VBSEnable, FMEEnable);
                    [colorReconstructed, referenceFrame] = reconstructed.reconstruct();

                    if marker == 1
                        intra = intraFrame(referenceFrame, width, height, i);
                        if isEntropy
                            mode = reshape(entropy(fgetl(mvFid), i).decode(0), numBlockHeight, numBlockWidth);
                        else
                            mode = reshape(str2num(fgetl(mvFid)), numBlockHeight, numBlockWidth);
                        end
                        if isDifferential == 1
                            mode = differentialCode(1, nRefFrames).decode(mode);
                        end

                        referenceFrame = intra.getPredicted(mode, numBlockHeight, numBlockWidth);
                        referenceFrames = {};
                    end
                end

                referenceFrames{length(referenceFrames) + 1} = frameBlocks(referenceFrame, i);
                if length(referenceFrames) > nRefFrames
                    referenceFrames(1) = [];
                end
                referenceFrameOnly = colorReconstructed(1 : height, 1 : width, :);
                figure(1);
                subplot(ceil(nframes / 5), 5, f), imshow(referenceFrameOnly);
                figure(2);
                subplot(ceil(nframes / 5), 5, f), imshow(referenceFrame(1 : height, 1 : width, :));

            end

            fclose('all');
        end
    end
end