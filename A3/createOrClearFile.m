function fid = createOrClearFile(fileName)
    outputFileExist = exist(fileName, 'file');
    
    if outputFileExist == 2
        fid=fopen(fileName,'w');
        fclose(fid);
    end

    fid=fopen(fileName,'a');
end