clear;
clc;

% Compare ParallalMode 0 and 2
mvFID1 = fopen("output\CIF\motionVectors.txt", "r");
mvFID2 = fopen("output\CIF\par2\motionVectors.txt", "r");

mvLine1 = fgetl(mvFID1);
mvLine2 = fgetl(mvFID2);

while mvLine1 ~= -1
    chars1 = char(mvLine1);
    chars2 = char(mvLine2);
    if ~all(chars1 == chars2)
        fprintf("not equal \n");
    end
    mvLine1 = fgetl(mvFID1);
    mvLine2 = fgetl(mvFID2);
end

fclose('all');


resFID1 = fopen("output\CIF\residual.txt", "r");
resFID2 = fopen("output\CIF\par2\residual.txt", "r");

resLine1 = fgetl(resFID1);
resLine2 = fgetl(resFID2);

while resLine1 ~= -1
    chars1 = char(resLine1);
    chars2 = char(resLine2);
    if ~all(chars1 == chars2)
        fprintf("not equal \n");
    end
    resLine1 = fgetl(resFID1);
    resLine2 = fgetl(resFID2);
end

fclose('all');


% Compare ParallalMode 0 and 3
mvFID1 = fopen("output\CIF\motionVectors.txt", "r");
mvFID2 = fopen("output\CIF\par3\motionVectors.txt", "r");

mvLine1 = fgetl(mvFID1);
mvLine2 = fgetl(mvFID2);

while mvLine1 ~= -1
    chars1 = char(mvLine1);
    chars2 = char(mvLine2);
    if ~all(chars1 == chars2)
        fprintf("not equal \n");
    end
    mvLine1 = fgetl(mvFID1);
    mvLine2 = fgetl(mvFID2);
end

fclose('all');


resFID1 = fopen("output\CIF\residual.txt", "r");
resFID2 = fopen("output\CIF\par3\residual.txt", "r");

resLine1 = fgetl(resFID1);
resLine2 = fgetl(resFID2);

while resLine1 ~= -1
    chars1 = char(resLine1);
    chars2 = char(resLine2);
    if ~all(chars1 == chars2)
        fprintf("not equal \n");
    end
    resLine1 = fgetl(resFID1);
    resLine2 = fgetl(resFID2);
end

fclose('all');
