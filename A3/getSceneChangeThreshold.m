function threashold = getSceneChangeThreshold(QP)
    switch QP
        case 0
            threashold = 1246;
        case 1
            threashold = 1127;
        case 2
            threashold = 850;
        case 3
            threashold = 628;
        case 4
            threashold = 452;
        case 5
            threashold = 304;
        case 6
            threashold = 192;
        case 7
            threashold = 108;
        case 8
            threashold = 52;
        case 9
            threashold = 24;
        case 10
            threashold = 11;
        case 11
            threashold = 7;
        otherwise
            error("unknown QP!");
    end
end