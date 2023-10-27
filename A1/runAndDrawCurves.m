function runAndDrawCurves(fig_title, x_axis, y_axis, varargin) % varargin: parameters
plotOutputPath = 'Plots\';
y(1:varargin{1}.nFrame, 1:(nargin-3)) = double(0.0);
x(1:varargin{1}.nFrame, 1:(nargin-3)) = y;

y_encoder_time(1:nargin-3) = double(0.0);
x_encoder_time(1:nargin-3) = y_encoder_time;

y_decoder_time(1:nargin-3) = y_encoder_time;
x_decoder_time(1:nargin-3) = y_encoder_time;

legends = strings([nargin-3, 1]);

if ~exist(plotOutputPath,'dir')
    mkdir(plotOutputPath)
end

for i = 1:(nargin-3)
    legends(i, :) = "IPP = " + int2str(varargin{i}.I_Period);
    x_encoder_time(i) = varargin{i}.I_Period;
    x_decoder_time(i) = varargin{i}.I_Period;

    tic
    ex4_encoder(varargin{i}.yuvInputFileName, varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, varargin{i}.r, varargin{i}.QP, varargin{i}.I_Period);
    toc;

    y_encoder_time(i) = toc;

    load('QTCCoeffs.mat', 'QTCCoeffs');
    load('MDiffs.mat', 'MDiffs');

    tic
    ex4_decoder(varargin{i}.nFrame, varargin{i}.width, varargin{i}.height, varargin{i}.blockSize, varargin{i}.QP, varargin{i}.I_Period, QTCCoeffs, MDiffs);
    toc;

    y_decoder_time(i) = toc;

    YOutput = importYOnly(varargin{i}.yuvOutputFileName, varargin{i}.width, varargin{i}.height ,varargin{i}.nFrame);
    [YOriginal, U, V] = importYUV(varargin{i}.yuvInputFileName, varargin{i}.width, varargin{i}.height, varargin{i}.nFrame);

    for j=1:varargin{i}.nFrame
        if (y_axis == "PSNR")
            y(j, i) = psnr(YOutput(:, :, j), YOriginal(:,:,j));
        elseif (y_axis == "Bitcount")
            if j == 1
                y(j, i) = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
            else
                y(j, i) = y(j - 1, i) + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
            end
        end

        if (x_axis == "FrameIndex")
            x(j, i) = j;
        elseif (x_axis == "Bitcount")
            if j == 1
                x(j, i) = sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
            else
                x(j, i) = x(j - 1, i) + sum(strlength(QTCCoeffs(j,:)), "all") + sum(strlength(MDiffs(j,:)), "all");
            end
        end

    end

end

plot(x, y, '-o');
title(fig_title);
xlabel(x_axis);
ylabel(y_axis);
legend(legends,'Location','southwest');
saveas(gcf, fullfile(plotOutputPath + x_axis + '_' + y_axis + '_' + int2str(varargin{1}.blockSize) + '_' + int2str(varargin{1}.r) + '_' + int2str(varargin{1}.QP) + '.jpeg'));
delete(gcf);

plot([x_encoder_time' x_decoder_time'], [y_encoder_time' y_decoder_time'], '-o');
title("Execution Times");
xlabel("IPP");
ylabel("time(s)");
legend({'Encoder', 'Decoder'},'Location','southwest');
saveas(gcf, fullfile(plotOutputPath + "Execution_Times_" + int2str(varargin{1}.blockSize) + '_' + int2str(varargin{1}.r) + '_' + int2str(varargin{1}.QP) + ".jpeg"));
