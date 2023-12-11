classdef rcEncoder
    %rcEncoder Summary of this class goes here
    properties
        filepath;
        width;
        height;
        nframes;
        QP;
        I_Period;
        RCflag;
        targetBR;
        QP_delta;
    end

    methods
        function obj = rcEncoder(filepath, width, height, nframes, QP, I_Period, RCflag, targetBR, QP_delta)
            obj.filepath = filepath;
            obj.width = width;
            obj.height = height;
            obj.nframes = nframes;
            obj.QP = QP;
            obj.I_Period = I_Period;
            obj.RCflag = RCflag;
            obj.targetBR = targetBR;
            obj.QP_delta = QP_delta;
        end

        function [psnrs, bitCounts] = encode(obj)
            if obj.RCflag == 0
                en = encoder(obj.filepath, obj.width, obj.height, obj.nframes, 16, 16,  2, obj.QP, obj.I_Period, 1, 1, 1, 1, 1, 1);
                [psnrs, bitCounts] = en.encode();
            else
                yVideo = yOnlyVideo(obj.filepath, obj.width, obj.height, obj.nframes);

                [pathstr,name,ext] = fileparts(obj.filepath);
                outputDir = "output/" + name;
                if ~exist(outputDir, 'dir')
                    mkdir(outputDir)
                end

                mvFID = fopen(outputDir + "/motionVectors.txt",'w');
                residualFID = fopen(outputDir + "/residual.txt", 'w');

                params = [obj.width, obj.height, obj.nframes, obj.QP, obj.RCflag, obj.QP_delta];
                fprintf(residualFID, '%s\n', entropy(double(params), 0).encode(0, 0));

                i = 16;
                j = 3;
                r = 16;
                n = 1;
                me = motionEstimator(yVideo.yframes(:, :, 1 : obj.nframes), i, obj.QP, 1, 1, 1, 1, j, 1);
                me = me.addReferenceFrame(uint8(128 * ones(obj.height, obj.width)));

                if obj.width == 352
                    rc_config = "data/config_cif.txt";
                else
                    rc_config = "data/config_qcif.txt";
                end

                rc = rateController(rc_config);
                bitPerFrame = rc.getBitPerFrame(obj.targetBR, obj.nframes);

                if obj.RCflag == 1
                    % Assume hypothetical for first frame
                    prevQPs = ones(1, ceil(obj.height / i)) * 4;
                    psnrs = [];
                    bitCounts = [];
                    for f = 1:obj.nframes
                        currFrame = yVideo.yframes(:, :, f);
                        rc = rc.resetBitPerFrame(bitPerFrame);

                        marker = obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0;
                        if marker == 1
                            frameType = "i";
                        else
                            frameType = "p";
                        end

                        marker = entropy(0, 0).getExpGolombValue(marker);
                        rc = rc.updateRemainingBit(strlength(marker));
                        fprintf(mvFID, '%s\n', marker);

                        fme = me.getRCFrameMotionEstimator(f);
                        fme = fme.addRateController(rc);

                        [QPs, splitStr, motionVectors, approximatedBlocks] = fme.getVariableBlocksPerRow(r, n, 1, prevQPs, frameType);
                        totalBitUsed = strlength(splitStr) + strlength(sprintf("%s", string(motionVectors))) + strlength(sprintf("%s", string(approximatedBlocks)));
                        fprintf(mvFID, "%s", splitStr);
                        fprintf(mvFID, "\n");
                        fprintf(mvFID, "%s ", string(motionVectors));
                        fprintf(mvFID, "\n");
                        fprintf(residualFID, "%s ", string(approximatedBlocks));
                        fprintf(residualFID, '\n');

                        [coloredY, reconstructedY] = fme.getReconstructedFrameWithQP(splitStr,...
                                                motionVectors, approximatedBlocks, obj.width, obj.height, 1, prevQPs);

                        prevQPs = QPs;
                        %subplot(ceil(obj.nframes / 7), 7, f), imshow(reconstructedY);

                        if obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0
                            intra = vbsIntraFrame(reconstructedY, obj.width, obj.height, i, 1, splitStr);
                            [modes, reconstructedY] = intra.predictVBS();
                            totalBitUsed = totalBitUsed + strlength(modes);
                            fprintf(mvFID, "%s", modes);
                            fprintf(mvFID, "\n");
                            me = me.clearReferenceFrames();
                        end
                        %fprintf("frame %d bit allocated %d bit used %d remain %d\n", f, bitPerFrame, totalBitUsed, bitPerFrame - totalBitUsed);
                        if f == 1
                            me = me.clearReferenceFrames();
                        end

                        me = me.addReferenceFrame(reconstructedY);
                        reconstructedY = reconstructedY(1 : obj.height, 1 : obj.width);
                        psnrs(f) = psnr(currFrame, reconstructedY);
                        bitCounts(f) = totalBitUsed;
                        %subplot(ceil(obj.nframes / 7), 7, f), imshow(reconstructedY);
                    end
                elseif obj.RCflag == 4
                    % Assume hypothetical for first frame
                    
                    prevQPs = ones(1, ceil(obj.height / i)) * 4;
                    psnrs = [];
                    bitCounts = [];
                    for f = 1:obj.nframes
                        currFrame = yVideo.yframes(:, :, f);
                        rc = rc.resetBitPerFrame(bitPerFrame);

                        marker = obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0;
                        if marker == 1
                            frameType = "i";
                        else
                            frameType = "p";
                        end

                        marker = entropy(0, 0).getExpGolombValue(marker);
                        rc = rc.updateRemainingBit(strlength(marker));
                        fprintf(mvFID, '%s\n', marker);

                        fme = me.getRCFrameMotionEstimator(f);
                        fme = fme.addRateController(rc);
                        fme = fme.addQPDelta(obj.QP_delta);

                        [QPs, splitStr, motionVectors, approximatedBlocks] = fme.getVariableBlocksPerRow(r, n, 1, prevQPs, frameType);
                        totalBitUsed = strlength(splitStr) + strlength(sprintf("%s", string(motionVectors))) + strlength(sprintf("%s", string(approximatedBlocks)));
                        fprintf(mvFID, "%s", splitStr);
                        fprintf(mvFID, "\n");
                        fprintf(mvFID, "%s ", string(motionVectors));
                        fprintf(mvFID, "\n");
                        fprintf(residualFID, "%s ", string(approximatedBlocks));
                        fprintf(residualFID, '\n');

                        [coloredY, reconstructedY] = fme.getReconstructedFrameWithQP(splitStr,...
                                                motionVectors, approximatedBlocks, obj.width, obj.height, 1, prevQPs);

                        prevQPs = QPs;
                        %subplot(ceil(obj.nframes / 7), 7, f), imshow(reconstructedY);

                        if obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0
                            intra = vbsIntraFrame(reconstructedY, obj.width, obj.height, i, 1, splitStr);
                            [modes, reconstructedY] = intra.predictVBS();
                            totalBitUsed = totalBitUsed + strlength(modes);
                            fprintf(mvFID, "%s", modes);
                            fprintf(mvFID, "\n");
                            me = me.clearReferenceFrames();
                        end
                        %fprintf("frame %d bit allocated %d bit used %d remain %d\n", f, bitPerFrame, totalBitUsed, bitPerFrame - totalBitUsed);
                        if f == 1
                            me = me.clearReferenceFrames();
                        end

                        me = me.addReferenceFrame(reconstructedY);
                        reconstructedY = reconstructedY(1 : obj.height, 1 : obj.width);
                        psnrs(f) = psnr(currFrame, reconstructedY);
                        bitCounts(f) = totalBitUsed;
                        %subplot(ceil(obj.nframes / 7), 7, f), imshow(reconstructedY);
                    end
                else
                    % multi pass
                    psnrs = [];
                    % assume QP for first frame
                    prevConstQP = 4;
                    prevQPs = ones(1, ceil(obj.height / i)) * 4;
                    previousTotalBits = 0;
                    for f = 1 : obj.nframes
                        currFrame = yVideo.yframes(:, :, f);
                        rc = rc.resetBitPerFrame(bitPerFrame);

                        fme = me.getRCFrameMotionEstimator(f);

                        marker = obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0;
                        QP = round(mean(prevQPs));

                        % first pass: run with constant QP
                        [bitPerRow, splitStr, motionVectors, approximatedBlocks] = fme.getVariableBlocksBitCounts(r, n, QP);
                        totalBit = sum(bitPerRow);

                        if marker == 0
                            %fprintf("frame %d, QP prev %d, curr %d\n", f, prevConstQP, QP);
                            %fprintf("frame %d, used prev %d, curr %d\n", f, previousTotalBits, totalBit);
                            % if p-frame is a scene change
                            if QP == prevConstQP
                                if totalBit / previousTotalBits > 1.5
                                    marker = 1;
                                end
                            else
                                prevEstimate = rc.getEstimatePBit(prevConstQP);
                                currEstimate = rc.getEstimatePBit(QP);
                                %fprintf("frame %d, estimate prev %d, curr %d\n", f, prevEstimate, currEstimate);
                                %fprintf("frame %d, diff prev %d, curr %d\n")
                                ratio = (abs(totalBit - previousTotalBits) * prevEstimate) / (previousTotalBits * currEstimate);
                                if ratio > 1.4
                                    marker = 1;
                                end
                            end

                        end

                        if marker == 1
                            frameType = "i";
                        else
                            frameType = "p";
                        end
                        rc = rc.setScalingFactor(QP, totalBit / length(bitPerRow), frameType);

                        previousTotalBits = totalBit;
                        prevConstQP = QP;

                        % save marker
                        marker = entropy(0, 0).getExpGolombValue(marker);
                        % rc = rc.updateRemainingBit(strlength(marker));
                        fprintf(mvFID, '%s\n', marker);

                        % second pass
                        totalBitUsed = 0;
                        if obj.RCflag == 2 || frameType == "i"
                            fme = me.getRCFrameMotionEstimator(f);
                            fme = fme.addRateController(rc);
                            [QPs, splitStr, motionVectors, approximatedBlocks] = fme.getVBPerRowProp(r, n, prevQPs, bitPerRow, frameType);
                        else
                            currFrameBlock = frameBlocks(currFrame, i);
                            rme = RCMotionEstimator(currFrameBlock, me.referenceFrames, 1, i);
                            rme = rme.addRateController(rc);
                            [QPs, motionVectors, approximatedBlocks] = rme.getVBPerRowWithMV(r, n, prevQPs, bitPerRow, frameType, motionVectors, splitStr);
                        end
                        totalBitUsed = strlength(splitStr) + strlength(sprintf("%s", string(motionVectors))) + strlength(sprintf("%s", string(approximatedBlocks)));
                        fprintf(mvFID, "%s", splitStr);
                        fprintf(mvFID, "\n");
                        fprintf(mvFID, "%s ", string(motionVectors));
                        fprintf(mvFID, "\n");
                        fprintf(residualFID, "%s ", string(approximatedBlocks));
                        fprintf(residualFID, '\n');

                        [coloredY, reconstructedY] = fme.getReconstructedFrameWithQP(splitStr,...
                                                motionVectors, approximatedBlocks, obj.width, obj.height, 1, prevQPs);

                        psnrs(f) = psnr(currFrame, reconstructedY);

                        %subplot(ceil(obj.nframes / 7), 7, f), imshow(reconstructedY(1 : obj.height, 1 : obj.width));
                        prevQPs = QPs;
                        if frameType == "i"
                            intra = vbsIntraFrame(reconstructedY, obj.width, obj.height, i, 1, splitStr);
                            [modes, reconstructedY] = intra.predictVBS();
                            totalBitUsed = totalBitUsed + strlength(modes);
                            fprintf(mvFID, "%s", modes);
                            fprintf(mvFID, "\n");
                            me = me.clearReferenceFrames();
                        end
                        if f == 1
                            me = me.clearReferenceFrames();
                        end
                        %fprintf("frame %d type %s\n", f, frameType);

                        bitCounts(f) = totalBitUsed;
                        me = me.addReferenceFrame(reconstructedY);
                        %reconstructedY = reconstructedY(1 : obj.height, 1 : obj.width);
                        %subplot(ceil(obj.nframes / 7), 7, f), imshow(reconstructedY);
                    end
                end
                fclose(mvFID);
                fclose(residualFID);
            end
        end
    end

end