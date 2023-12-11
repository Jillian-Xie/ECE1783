classdef parallelEncoder
    %parallelEncoder Summary of this class goes here
    properties
        filepath;
        width;
        height;
        nframes;
        QP;
        I_Period;
        ParallelMode;
        RCflag;
        targetBR;
    end

    methods
        function obj = parallelEncoder(filepath, width, height, nframes, QP, I_Period, ParallelMode, RCflag, targetBR)
            obj.filepath = filepath;
            obj.width = width;
            obj.height = height;
            obj.nframes = nframes;
            obj.QP = QP;
            obj.I_Period = I_Period;
            obj.ParallelMode = ParallelMode;
            obj.RCflag = RCflag;
            obj.targetBR = targetBR;
        end

        function [psnrs, bitCounts] = encode(obj)
            if obj.ParallelMode == 0
                [psnrs, bitCounts] = obj.encodeInBlocks();
            elseif obj.ParallelMode == 1
                [psnrs, bitCounts] = obj.encodeExtremeBlockParallel();
            elseif obj.ParallelMode == 2
                [psnrs, bitCounts] = obj.encodeBlockParallel();
            elseif obj.ParallelMode == 3
                [psnrs, bitCounts] = obj.encodeFrameParallel();
            end
            fclose('all');
        end

        function [psnrs, bitCounts] = encodeInBlocks(obj)
            i = 16;
            j = 3;
            r = 16;
            n = 1;
            QP = obj.QP;
            FastME = 1;

            [pathstr,name,ext] = fileparts(obj.filepath);
            outputDir = "output/" + name;
            if ~exist(outputDir, 'dir')
                mkdir(outputDir)
            end

            mvFID = fopen(outputDir + "/motionVectors.txt",'w');
            residualFID = fopen(outputDir + "/residual.txt", 'w');
            params = [obj.width, obj.height, obj.nframes, 1, i, QP, 1, 1, 1, 1];
            fprintf(residualFID, "%s\n", entropy(double(params), 0).encode(0, 0));

            yVideo = yOnlyVideo(obj.filepath, obj.width, obj.height, obj.nframes);
            me = motionEstimator(yVideo.yframes(:, :, 1 : obj.nframes), i, QP, 1, 1, 1, 1, j, 1);
            me = me.addReferenceFrame(uint8(128 * ones(obj.height, obj.width)));
            psnrs = [];
            bitCounts = [];
            for f  = 1 : obj.nframes
                fme = me.getFrameMotionEstimator(f);
                marker = obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0;

                splitStr = {};
                motionVectors = {};
                approximatedBlocks = {};
                modes = {};
                reconstructedY = {};
                intraV = ones(1, obj.width) * 128;
                for x = 1 : fme.currFrame.height / i
                    tempStr = {};
                    tempMV = {};
                    tempRes = {};
                    tempRecontructed = {};
                    if marker == 1
                        tempModes = {};
                    end
                    prevMV = zeros(1, 2);
                    intraH = ones(i, 1) * 128;
                    for y = 1 : fme.currFrame.width / i
                        oldPrev = prevMV;
                        [splitS, entropyedMV, entropyedResidual, prevMV] = fme.getVariableBlockWithRef(r, n, FastME, QP, x, y, prevMV);
                        tempStr{y} = splitS;
                        tempMV{y} = entropyedMV;
                        tempRes{y} = entropyedResidual;
                        reconstructedBlock = fme.getReconstructedBlock(char(splitS), entropyedMV, entropyedResidual, obj.width, obj.height, oldPrev, x, y);
                        % tempRecontructed{y} = fme.getReconstructedBlock(char(splitS), entropyedMV, entropyedResidual, obj.width, obj.height, oldPrev, x, y);
                        if marker == 1
                            [mode, intraBlock] = fme.getIntraMode(char(splitS), reconstructedBlock, intraH, intraV((y - 1) * i + 1 : y * i));
                            intraV((y - 1) * i + 1 : y * i) = reconstructedBlock(i, :);
                            intraH = reconstructedBlock(:, i);
                            tempModes{y} = mode;
                            reconstructedBlock = intraBlock;
                        end
                        tempRecontructed{y} = reconstructedBlock;
                    end
                    splitStr(x) = {strjoin(string(tempStr), "")};
                    motionVectors(x, :) = tempMV;
                    approximatedBlocks(x, :) = tempRes;
                    reconstructedY(x, :) = tempRecontructed;
                    if marker == 1
                        modes(x, :) = tempModes;
                    end
                end
                splitString = strjoin(string(splitStr), "");
                reconstructedY = uint8(cell2mat(reconstructedY));
                % [coloredY, reconstructedY] = fme.getReconstructedFrame(char(splitString), motionVectors, approximatedBlocks, obj.width, obj.height, 1);

                psnrs(f) = psnr(fme.currFrame.frameData, reconstructedY);
                totalBits = strlength(splitString) + strlength(sprintf("%s ", string(motionVectors))) + strlength(sprintf("%s ", string(approximatedBlocks)));

                fprintf(mvFID, "%s\n", entropy(0, 0).getExpGolombValue(marker));
                fprintf(mvFID, "%s", splitString);
                fprintf(mvFID, "\n");
                fprintf(mvFID, "%s ", string(motionVectors));
                fprintf(mvFID, "\n");
                if marker == 1
                    modes = fme.getEntropyedModes(string(modes));
                    totalBits = totalBits + strlength(modes);
                    fprintf(mvFID, "%s", modes);
                    fprintf(mvFID, "\n");
                end
                fprintf(residualFID, "%s ", string(approximatedBlocks));
                fprintf(residualFID, "\n");

                bitCounts(f) = totalBits;
                me = me.clearReferenceFrames();
                me = me.addReferenceFrame(reconstructedY);
                % subplot(ceil(obj.nframes / 7), 7, f), imshow(reconstructedY);
            end
            fclose('all');
        end

        function [psnrs, bitCounts] = encodeFrameParallel(obj)
            i = 16;
            j = 3;
            r = 16;
            n = 1;
            QP = obj.QP;
            prevMV = zeros(1, 2);
            FastME = 1;

            [pathstr,name,ext] = fileparts(obj.filepath);
            outputDir = "output/" + name;
            if ~exist(outputDir, 'dir')
                mkdir(outputDir)
            end

            if ~exist(outputDir + "/par3", 'dir')
                mkdir(outputDir + "/par3")
            end

            mvFile = outputDir + "/par3/motionVectors.txt";
            residualFile = outputDir + "/par3/residual.txt";

            residualFID = fopen(residualFile, 'w');
            params = [obj.width, obj.height, obj.nframes, 1, i, QP, 1, 1, 1, 1];
            fprintf(residualFID, "%s\n", entropy(double(params), 0).encode(0, 0));
            fclose(residualFID);

            mvFID = fopen(mvFile, 'w');
            fclose(mvFID);

            yVideo = yOnlyVideo(obj.filepath, obj.width, obj.height, obj.nframes);
            me = motionEstimator(yVideo.yframes(:, :, 1 : obj.nframes), i, QP, 1, 1, 1, 1, j, 1);
            psnrs = [];
            bitCounts = [];

            rowNumbers = ceil(obj.height / i);
            colNumbers = ceil(obj.width / i);
            mvL = 2;

            spmd(2)
                if spmdIndex == 1
                    for f = 1 : 2 : obj.nframes
                        % receive reference frame from f - 1
                        if f == 1
                            referencedFrame = uint8(128 * ones(obj.height, obj.width));
                        else
                            referencedFrame = spmdReceive(2);
                        end
                        me = me.clearReferenceFrames();
                        me = me.addReferenceFrame(referencedFrame);
                        fme = me.getFrameMotionEstimator(f);

                        marker = obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0;

                        splitStr = {};
                        motionVectors = {};
                        approximatedBlocks = {};
                        modes = {};
                        reconstructedY = {};
                        intraV = ones(1, obj.width) * 128;

                        % starts  encoding
                        for x = 1 : rowNumbers
                            tempStr = {};
                            tempMV = {};
                            tempRes = {};
                            tempRecontructed = {};
                            if marker == 1
                                tempModes = {};
                            end
                            prevMV = zeros(1, 2);
                            intraH = ones(i, 1) * 128;
                            for y = 1 : colNumbers
                                oldPrev = prevMV;
                                [splitS, entropyedMV, entropyedResidual, prevMV] = fme.getVariableBlockWithRef(r, n, FastME, QP, x, y, prevMV);
                                tempStr{y} = splitS;
                                tempMV{y} = entropyedMV;
                                tempRes{y} = entropyedResidual;
                                reconstructedBlock = fme.getReconstructedBlock(char(splitS), entropyedMV, entropyedResidual, obj.width, obj.height, oldPrev, x, y);
                                if marker == 1
                                    [mode, intraBlock] = fme.getIntraMode(char(splitS), reconstructedBlock, intraH, intraV((y - 1) * i + 1 : y * i));
                                    intraV((y - 1) * i + 1 : y * i) = reconstructedBlock(i, :);
                                    intraH = reconstructedBlock(:, i);
                                    tempModes{y} = mode;
                                    reconstructedBlock = intraBlock;
                                end
                                tempRecontructed{y} = reconstructedBlock;
                            end
                            splitStr(x) = {strjoin(string(tempStr), "")};
                            motionVectors(x, :) = tempMV;
                            approximatedBlocks(x, :) = tempRes;
                            reconstructedY(x, :) = tempRecontructed;
                            if marker == 1
                                modes(x, :) = tempModes;
                            end
                            if f ~= obj.nframes
                                % do not need to send if its is already the frame
                                spmdSend(cell2mat(tempRecontructed), 2);
                            end
                        end

                        % write SplitStr, MV, Modes, Residual to file
                        mvFid = fopen(mvFile, 'a');
                        resFid = fopen(residualFile, 'a');
                        splitString = strjoin(string(splitStr), "");
                        fprintf(mvFid, "%s\n", entropy(0, 0).getExpGolombValue(marker));
                        fprintf(mvFid, "%s", splitString);
                        fprintf(mvFid, "\n");
                        fprintf(mvFid, "%s ", string(motionVectors));
                        fprintf(mvFid, "\n");
                        if marker == 1
                            modes = fme.getEntropyedModes(string(modes));
                            fprintf(mvFid, "%s", modes);
                            fprintf(mvFid, "\n");
                        end
                        fprintf(resFid, "%s ", string(approximatedBlocks));
                        fprintf(resFid, "\n");
                        fclose(mvFid);
                        fclose(resFid);

                        % generate reference frame 
                        reconstructedY = uint8(cell2mat(reconstructedY));

                        if f ~= obj.nframes
                            spmdSend(1, 2);
                        end
                    end
                elseif spmdIndex == 2
                    for f = 2 : 2 : obj.nframes
                        % frame f starts to encode row N when row N+2 finishes encoding in frame f - 1
                        referencedFrame = uint8(zeros(obj.height, obj.width));

                        me = me.clearReferenceFrames();
                        me = me.addReferenceFrame(referencedFrame);
                        fme = me.getFrameMotionEstimator(f);

                        marker = obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0;

                        splitStr = {};
                        motionVectors = {};
                        approximatedBlocks = {};
                        modes = {};
                        reconstructedY = {};
                        intraV = ones(1, obj.width) * 128;

                        % wait for previous frame first rows finish
                        firstRow = spmdReceive(1);
                        fme = fme.updateRefFrame(firstRow, 1);
                        % starts  encoding
                        for x = 1 : rowNumbers
                            if x ~= rowNumbers
                                preFrameRow = spmdReceive(1);
                                % wait for row from previous frame finishes
                                fme = fme.updateRefFrame(preFrameRow, x + 1);
                            end

                            tempStr = {};
                            tempMV = {};
                            tempRes = {};
                            tempRecontructed = {};
                            if marker == 1
                                tempModes = {};
                            end
                            prevMV = zeros(1, 2);
                            intraH = ones(i, 1) * 128;
                            for y = 1 : colNumbers
                                oldPrev = prevMV;
                                [splitS, entropyedMV, entropyedResidual, prevMV] = fme.getVariableBlockWithRef(r, n, FastME, QP, x, y, prevMV);
                                tempStr{y} = splitS;
                                tempMV{y} = entropyedMV;
                                tempRes{y} = entropyedResidual;
                                reconstructedBlock = fme.getReconstructedBlock(char(splitS), entropyedMV, entropyedResidual, obj.width, obj.height, oldPrev, x, y);
                                if marker == 1
                                    [mode, intraBlock] = fme.getIntraMode(char(splitS), reconstructedBlock, intraH, intraV((y - 1) * i + 1 : y * i));
                                    intraV((y - 1) * i + 1 : y * i) = reconstructedBlock(i, :);
                                    intraH = reconstructedBlock(:, i);
                                    tempModes{y} = mode;
                                    reconstructedBlock = intraBlock;
                                end
                                tempRecontructed{y} = reconstructedBlock;
                            end
                            splitStr(x) = {strjoin(string(tempStr), "")};
                            motionVectors(x, :) = tempMV;
                            approximatedBlocks(x, :) = tempRes;
                            reconstructedY(x, :) = tempRecontructed;
                            if marker == 1
                                modes(x, :) = tempModes;
                            end
                        end

                        % wait for frame f - 1 finish write to file
                        msg = spmdReceive(1);
                        mvFid = fopen(mvFile, 'a');
                        resFid = fopen(residualFile, 'a');
                        splitString = strjoin(string(splitStr), "");
                        fprintf(mvFid, "%s\n", entropy(0, 0).getExpGolombValue(marker));
                        fprintf(mvFid, "%s", splitString);
                        fprintf(mvFid, "\n");
                        fprintf(mvFid, "%s ", string(motionVectors));
                        fprintf(mvFid, "\n");
                        if marker == 1
                            modes = fme.getEntropyedModes(string(modes));
                            fprintf(mvFid, "%s", modes);
                            fprintf(mvFid, "\n");
                        end
                        fprintf(resFid, "%s ", string(approximatedBlocks));
                        fprintf(resFid, "\n");
                        fclose(mvFid);
                        fclose(resFid);

                        % generate reference frame 
                        reconstructedY = uint8(cell2mat(reconstructedY));

                        % send reference frame to f + 1
                        if f ~= obj.nframes
                            spmdSend(reconstructedY, 1);
                        end
                    end
                end
                % spmdBarrier;

                % tf = spmdProbe
                % if tf
                %     notR = spmdReceive;
                %     fprintf("%s", string(notR));
                % end
            end
        end

 
        function [psnrs, bitCounts] = encodeBlockParallel(obj)
            % introduce a delay of 

            % for both i-frame and p-frame, 2 rows are encoded in parallel
            % thread 1: encode block N + 1 in row i, write, wait thread 2 finish
            % thread 2: wait block N in row i finish, encode block N + 1, wait thread 1 write finish
            % once both thread 1, 2 finish, start next two rows.

            i = 16;
            j = 3;
            r = 16;
            n = 1;
            QP = obj.QP;
            FastME = 1;

            [pathstr,name,ext] = fileparts(obj.filepath);
            outputDir = "output/" + name;
            if ~exist(outputDir, 'dir')
                mkdir(outputDir)
            end

            if ~exist(outputDir + "/par2", 'dir')
                mkdir(outputDir + "/par2")
            end

            mvFile = outputDir + "/par2/motionVectors.txt";
            residualFile = outputDir + "/par2/residual.txt";

            residualFID = fopen(residualFile, 'w');
            params = [obj.width, obj.height, obj.nframes, 1, i, QP, 1, 1, 1, 1];
            fprintf(residualFID, "%s\n", entropy(double(params), 0).encode(0, 0));
            fclose(residualFID);

            mvFID = fopen(mvFile, 'w');
            fclose(mvFID);

            yVideo = yOnlyVideo(obj.filepath, obj.width, obj.height, obj.nframes);
            me = motionEstimator(yVideo.yframes(:, :, 1 : obj.nframes), i, QP, 1, 1, 1, 1, j, 1);
            me = me.addReferenceFrame(uint8(128 * ones(obj.height, obj.width)));
            psnrs = [];
            bitCounts = [];

            rowNumbers = ceil(obj.height / i);
            colNumbers = ceil(obj.width / i);
            mvL = 2;

            for f  = 1 : obj.nframes

                marker = obj.I_Period > 0 && rem(f - 1, obj.I_Period) == 0;
                entropyedMarker = entropy(0, 0).getExpGolombValue(marker);
                mvFID = fopen(mvFile, 'a');
                fprintf(mvFID, '%s\n', entropyedMarker);
                fclose(mvFID);

                fme = me.getFrameMotionEstimator(f);

                spmd(2)
                    if spmdIndex == 1
                        % odd rows
                        for row = 1 : 2 : rowNumbers
                            if row ~= 1
                                intraV = spmdReceive(2);
                            else
                                intraV = ones(1, obj.width) * 128;
                            end
                            prevMV = zeros(1, 2);
                            tempStr = {};
                            tempMV = {};
                            tempRes = {};
                            tempRecontructed = {};
                            if marker == 1
                                tempModes = {};
                            end
                            intraH = ones(i, 1) * 128;
                            for col = 1 : colNumbers
                                oldPrev = prevMV;
                                [splitS, entropyedMV, entropyedResidual, prevMV] = fme.getVariableBlockWithRef(r, n, FastME, obj.QP, row, col, prevMV);

                                reconstructedBlock = fme.getReconstructedBlock(char(splitS), entropyedMV, entropyedResidual, obj.width, obj.height, oldPrev, row, col);
                                if marker == 1
                                    [mode, intraBlock] = fme.getIntraMode(char(splitS), reconstructedBlock, intraH, intraV((col - 1) * i + 1 : col * i));
                                    nextIntraV = reconstructedBlock(i, :);
                                    intraH = reconstructedBlock(:, i);
                                    tempModes{col} = mode;
                                    reconstructedBlock = intraBlock;
                                end

                                tempStr{col} = splitS;
                                tempMV{col} = entropyedMV;
                                tempRes{col} = entropyedResidual;
                                tempRecontructed{col} = reconstructedBlock;

                                if marker == 1
                                    spmdSend(nextIntraV, 2);
                                else
                                    spmdSend(col, 2);
                                end
                            end

                            if row == 1
                                tempFid = fopen(outputDir + "/par2/temp.txt", 'w');
                            else
                                tempFid = fopen(outputDir + "/par2/temp.txt", 'a');
                            end
                            fprintf(tempFid, "%s", strjoin(string(tempStr), ""));
                            fprintf(tempFid, "\n");
                            fprintf(tempFid, "%s ", string(tempMV));
                            fprintf(tempFid, "\n");
                            if marker == 1
                                fprintf(tempFid, "%s", string(tempModes));
                                fprintf(tempFid, "\n");
                            end
                            fprintf(tempFid, "%s ", string(tempRes));
                            fprintf(tempFid, "\n");
                            fclose(tempFid);

                            reconstructedY(row, :) = tempRecontructed;
                            if row ~= rowNumbers
                                spmdSend(1, 2);
                            end
                        end
                    elseif spmdIndex == 2
                         % even rows
                        for row = 2 : 2 : rowNumbers
                            if marker == 1
                                intraV = zeros(1, obj.width);
                            else
                                intraV = zeros(1, 1);
                            end

                            prevMV = zeros(1, 2);
                            tempStr = {};
                            tempMV = {};
                            tempRes = {};
                            tempRecontructed = {};
                            if marker == 1
                                tempModes = {};
                            end
                            intraH = ones(i, 1) * 128;
                            for col = 1 : colNumbers
                                receivedV = spmdReceive(1);
                                oldPrev = prevMV;
                                [splitS, entropyedMV, entropyedResidual, prevMV] = fme.getVariableBlockWithRef(r, n, FastME, obj.QP, row, col, prevMV);

                                reconstructedBlock = fme.getReconstructedBlock(char(splitS), entropyedMV, entropyedResidual, obj.width, obj.height, oldPrev, row, col);
                                if marker == 1
                                    [mode, intraBlock] = fme.getIntraMode(char(splitS), reconstructedBlock, intraH, receivedV);
                                    intraV((col - 1) * i + 1 : col * i) = reconstructedBlock(i, :);
                                    intraH = reconstructedBlock(:, i);
                                    tempModes{col} = mode;
                                    reconstructedBlock = intraBlock;
                                end

                                tempStr{col} = splitS;
                                tempMV{col} = entropyedMV;
                                tempRes{col} = entropyedResidual;
                                tempRecontructed{col} = reconstructedBlock;
                            end

                            startWrite = spmdReceive(1);
                            tempFid = fopen(outputDir + "/par2/temp.txt", 'a');
                            fprintf(tempFid, "%s", strjoin(string(tempStr), ""));
                            fprintf(tempFid, "\n");
                            fprintf(tempFid, "%s ", string(tempMV));
                            fprintf(tempFid, "\n");
                            if marker == 1
                                fprintf(tempFid, "%s", string(tempModes), "");
                                fprintf(tempFid, "\n");
                            end
                            fprintf(tempFid, "%s ", string(tempRes));
                            fprintf(tempFid, "\n");
                            fclose(tempFid);
                            reconstructedY(row, :) = tempRecontructed;
                            if row ~= rowNumbers
                                spmdSend(intraV, 1);
                            end
                        end
                    end

                    % spmdBarrier;

                    % tf = spmdProbe
                    % if tf
                    %     notR = spmdReceive;
                    %     fprintf("%s", string(notR));
                    % end
                end

                tempFID = fopen(outputDir + "/par2/temp.txt", 'r');
                line = fgetl(tempFID);
                s = "";
                mvLines = strings(1, colNumbers);
                resLines = strings(1, colNumbers);
                if marker == 1
                    modeLines =  "";
                end
                while line ~= -1
                    s = s + line;
                    mv = strsplit(strtrim(fgetl(tempFID)));
                    mvLines = mvLines + mv + " ";
                    if marker == 1
                        modeLines = modeLines + strtrim(fgetl(tempFID));
                    end
                    res = strsplit(strtrim(fgetl(tempFID)));
                    resLines = resLines + res + " ";
                    line = fgetl(tempFID);
                end
                fclose(tempFID);
                mvFID = fopen(mvFile, 'a');
                residualFID = fopen(residualFile, 'a');
                fprintf(mvFID, "%s", s);
                fprintf(mvFID, "\n");
                fprintf(mvFID, "%s", mvLines);
                fprintf(mvFID, "\n");
                if marker == 1
                    modes = fme.getEntropyedModes(modeLines);
                    fprintf(mvFID, "%s", modes);
                    fprintf(mvFID, "\n");
                end
                fprintf(residualFID, "%s", resLines);
                fprintf(residualFID, "\n");
                fclose(residualFID);
                fclose(mvFID);

                referencedFrame = {};
                frame1 = reconstructedY{1};
                frame2 = reconstructedY{2};
                for row = 1 : rowNumbers
                    if rem(row, 2) == 1
                        referencedFrame{row} = cell2mat(frame1(row, :));
                    else
                        referencedFrame{row} = cell2mat(frame2(row, :));
                    end
                end
                referencedFrame = uint8(cell2mat(referencedFrame'));
                me = me.clearReferenceFrames();
                me = me.addReferenceFrame(referencedFrame);
                % subplot(ceil(obj.nframes / 7), 7, f), imshow(referencedFrame);
            end
        end


        function [psnrs, bitCounts] = encodeExtremeBlockParallel(obj)
            % This opens default threads, and run all blocks in parallel
            % blocks in the frame are encoded in parallel, and all block are referenced 128 gray
            % disable differential and intra prediction
            i = 16;
            j = 3;
            r = 16;
            n = 1;
            QP = obj.QP;
            FastME = 1;

            [pathstr,name,ext] = fileparts(obj.filepath);
            outputDir = "output/" + name;
            if ~exist(outputDir, 'dir')
                mkdir(outputDir)
            end

            if ~exist(outputDir + "/par1", 'dir')
                mkdir(outputDir + "/par1")
            end

            mvFile = outputDir + "/par1/motionVectors.txt";
            residualFile = outputDir + "/par1/residual.txt";

            mvFID = fopen(mvFile,'w');
            residualFID = fopen(residualFile, 'w');
            params = [obj.width, obj.height, obj.nframes, 1, i, QP, 0, 1, 1, 1];
            fprintf(residualFID, "%s\n", entropy(double(params), 0).encode(0, 0));

            yVideo = yOnlyVideo(obj.filepath, obj.width, obj.height, obj.nframes);
            me = motionEstimator(yVideo.yframes(:, :, 1 : obj.nframes), i, QP, 0, 1, 1, 1, j, 1);
            me = me.addReferenceFrame(uint8(128 * ones(obj.height, obj.width)));
            psnrs = [];
            bitCounts = [];
            for f  = 1 : obj.nframes
                fme = me.getFrameMotionEstimator(f);
                splitStr = {};
                motionVectors = {};
                approximatedBlocks = {};
                reconstructedY = {};
                parfor (x = 1 : fme.currFrame.height / i, 8)
                    tempStr = {};
                    tempMV = {};
                    tempRes = {};
                    tempRecontructed = {};
                    for y = 1 : fme.currFrame.width / i
                        [splitS, entropyedMV, entropyedResidual] = fme.getVariableBlock(r, n, FastME, QP, x, y);
                        tempStr{y} = splitS;
                        tempMV{y} = entropyedMV;
                        tempRes{y} = entropyedResidual;
                        tempRecontructed{y} = fme.getReconstructedBlock(char(splitS), entropyedMV, entropyedResidual, obj.width, obj.height, zeros(1, 2), x, y);
                    end
                    splitStr(x) = {strjoin(string(tempStr), "")};
                    motionVectors(x, :) = tempMV;
                    approximatedBlocks(x, :) = tempRes;
                    reconstructedY(x, :) = tempRecontructed;
                end
                splitString = strjoin(string(splitStr), "");
                reconstructedY = uint8(cell2mat(reconstructedY));

                % subplot(ceil(obj.nframes / 7), 7, f), imshow(reconstructedY);

                % me = me.clearReferenceFrames();
                % me = me.addReferenceFrame(reconstructedY);

                psnrs(f) = psnr(fme.currFrame.frameData, reconstructedY);
                bitCounts(f) = strlength(splitString) + strlength(sprintf("%s ", string(motionVectors))) + strlength(sprintf("%s ", string(approximatedBlocks)));

                fprintf(mvFID, "%s\n", entropy(0, 0).getExpGolombValue(0));
                fprintf(mvFID, "%s", splitString);
                fprintf(mvFID, "\n");
                fprintf(mvFID, "%s ", string(motionVectors));
                fprintf(mvFID, "\n");
                fprintf(residualFID, "%s ", string(approximatedBlocks));
                fprintf(residualFID, "\n");
            end
            fclose('all');
        end
    end

end