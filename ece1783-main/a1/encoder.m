classdef encoder
    %encoder Summary of this class goes here
    properties
        filepath;
        width;
        height;
        nframes;
        i;
        r;
        n;
        QP;
        I_Period;
        isDifferential;
        isEntropy;
        nRefFrames;
        VBSEnable;
        FMEEnable;
        FastME;
    end

    methods
        function obj = encoder(filepath, width, height, nframes, ...
                i, r, n, QP, I_Period, isDifferential, isEntropy, ...
                nRefFrames, VBSEnable, FMEEnable, FastME)
            obj.filepath = filepath;
            obj.width = width;
            obj.height = height;
            obj.nframes = nframes;
            obj.i = i;
            obj.r = r;
            obj.n = n;
            obj.QP = QP;
            obj.I_Period = I_Period;
            obj.isDifferential = isDifferential;
            obj.isEntropy = isEntropy;
            obj.VBSEnable = VBSEnable;
            obj.FMEEnable = FMEEnable;
            obj.FastME = FastME;
            if obj.VBSEnable == 1 && obj.QP < 0
                % use QP when VBS is enabled
                obj.QP = 3;
            end
            if obj.VBSEnable == 1 && obj.isEntropy == 0
                % isEntropy when VBS is enabled
                obj.isEntropy = 1;
            end
            if nRefFrames <= 0
                obj.nRefFrames = 1;
            else
                obj.nRefFrames = nRefFrames;
            end
        end

        function [psnrs, bitCounts] = encode(obj)
            yVideo = yOnlyVideo(obj.filepath, obj.width, obj.height, obj.nframes);

            [pathstr,name,ext] = fileparts(obj.filepath);
            outputDir = "output/" + name;
            if ~exist(outputDir, 'dir')
                mkdir(outputDir)
            end

            mvFID = fopen(outputDir + "/motionVectors.txt",'w');
            residualFID = fopen(outputDir + "/residual.txt", 'w');

            params = [obj.width, obj.height, obj.nframes, obj.nRefFrames, obj.i, obj.QP, ...
                obj.isDifferential, obj.isEntropy, obj.VBSEnable, obj.FMEEnable];
            if obj.isEntropy
                fprintf(residualFID, '%s\n', entropy(double(params), 0).encode(0, 0));
            else
                fprintf(residualFID, '%d ', params);
                fprintf(residualFID, '\n');
            end

            j = 0;
            if obj.VBSEnable == 1
                j = floor(log2(double(obj.i))) - 1;
                if j > 4
                    j = 4;
                end
            end

            me = motionEstimator(yVideo.yframes(:, :, 1 : obj.nframes), ...
                obj.i, obj.QP, obj.isDifferential, obj.isEntropy, ...
                obj.nRefFrames, obj.VBSEnable, j, obj.FMEEnable);
            me = me.addReferenceFrame(uint8(128 * ones(obj.height, obj.width)));

            totalBitSize = 0;
            totalPSNR = 0;
            psnrs = [];
            bitCounts = [];
            for f = 1:obj.nframes
                totalSize = 0;
                currFrame = yVideo.yframes(:, :, f);
                % add a I/P frame marker to MV
                marker = obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0;
                if obj.isEntropy
                    fprintf(mvFID, '%s\n', entropy(0, 0).getExpGolombValue(marker));
                else
                    fprintf(mvFID, '%d\n', marker);
                end

                fme = me.getFrameMotionEstimator(f);

                % save approximated residual
                if obj.VBSEnable == 0
                    % save mv
                    [maes, motionVectors] = fme.getBestPredictedBlocks(obj.r, 1, obj.FastME);

                    differentialMV = me.getDifferential(0, cell2mat(motionVectors));
                    entropyed = me.getEntropy(0, differentialMV);
                    totalSize = totalSize + strlength(entropyed);
                    fprintf(mvFID, "%s", entropyed);
                    fprintf(mvFID, "\n");
                    approximatedBlocks = fme.getApproximatedResidualBlocks(motionVectors, obj.n);

                    % quatization if QP is set
                    if obj.QP >= 0
                        dctTransformed = fme.getDCTBlocks(approximatedBlocks);
                        QTC = fme.getQuatizedBlocks(dctTransformed, obj.QP);
                        entropyed = me.getEntropy(1, QTC);
                        entropyed = me.getEntropy(0, entropyed);
                        totalSize = totalSize + strlength(entropyed);
                        fprintf(residualFID, "%s", entropyed);
                        fprintf(residualFID, "\n");
                        approximatedBlocks = rescaledFrame(QTC, obj.i, obj.QP).rescaled();
                    else
                        entropyed = me.getEntropy(1, approximatedBlocks);
                        entropyed = me.getEntropy(0, entropyed);
                        totalSize = totalSize + strlength(entropyed);
                        fprintf(residualFID, "%s", entropyed);
                        fprintf(residualFID, '\n');
                    end

                    [coloredY, reconstructedY] = fme.getReconstructedFrame(motionVectors, approximatedBlocks, obj.nRefFrames, obj.VBSEnable, obj.FMEEnable);
                else
                    % variable blockSize
                    [splitStr, motionVectors, approximatedBlocks] = fme.getVariableBlocks(obj.r, obj.n, obj.FastME);
                    totalSize = totalSize + strlength(splitStr) + strlength(sprintf("%s ", string(motionVectors))) + strlength(sprintf("%s ", string(approximatedBlocks)));
                    fprintf(mvFID, "%s", splitStr);
                    fprintf(mvFID, "\n");
                    fprintf(mvFID, "%s ", string(motionVectors));
                    fprintf(mvFID, "\n");

                    fprintf(residualFID, "%s ", string(approximatedBlocks));
                    fprintf(residualFID, '\n');

                    [coloredY, reconstructedY] = fme.getReconstructedFrame(splitStr,...
                                         motionVectors, approximatedBlocks, obj.width, obj.height, obj.FMEEnable);
                end

                psnrs(f) = psnr(currFrame, reconstructedY);
                % move IPeriod to me
                if obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0
                    if obj.VBSEnable == 0
                        intra = intraFrame(reconstructedY, obj.width, obj.height, obj.i);
                        [modes, reconstructedY] = intra.predict();

                        differentialModes = me.getDifferential(1, modes);
                        entropyed = me.getEntropy(0, differentialModes);
                        totalSize = totalSize + strlength(entropyed);
                        fprintf(mvFID, "%s", entropyed);
                        fprintf(mvFID, "\n");
                    else
                        % VBS enabled
                        intra = vbsIntraFrame(reconstructedY, obj.width, obj.height, obj.i, obj.isDifferential, splitStr);
                        [modes, reconstructedY] = intra.predictVBS();
                        totalSize = totalSize + strlength(modes);

                        fprintf(mvFID, "%s", modes);
                        fprintf(mvFID, "\n");
                    end

                    me = me.clearReferenceFrames();
                end

                if f == 1
                    me = me.clearReferenceFrames();
                end
                me = me.addReferenceFrame(reconstructedY);
                reconstructedY = reconstructedY(1 : obj.height, 1 : obj.width);
                % save reconstructed Y
                %figure(1);
                %subplot(ceil(obj.nframes / 7), 7, f), imshow(coloredY(1 : obj.height, 1 : obj.width, :));
                %figure(2);
                %subplot(ceil(obj.nframes / 5), 5, f), imshow(reconstructedY);

                bitCounts(f) = totalSize;
                totalPSNR = totalPSNR + psnr(currFrame, reconstructedY);
                % if f ~= 1
                %     totalBitSize = totalBitSize + totalSize;
                % end
            end
            %totalBitSize = totalBitSize / 18;
            %totalBitSize = totalBitSize / 20;
            %fprintf("QP = %d, total bit size %.2f \n", obj.QP, totalBitSize);
            %fprintf("PSNR = %d \n", totalPSNR );
            fclose(mvFID);
            fclose(residualFID);
        end
    end
end